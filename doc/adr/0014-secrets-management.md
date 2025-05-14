# 14. Secrets Management

Date: 2025-03-17

## Status
Accepted  

## Context  

Mission applications require robust secrets management, especially when secret values (credentials, API keys, certificates, etc.) are stored and rotated outside the cluster (e.g., in cloud secret managers or vaults). In our Kubernetes clusters, we need a way to pull in these externally managed secrets and keep them in sync. Without an automated solution, a secret update in an external store might not reflect in the cluster, leaving applications running with stale or invalid credentials. Furthermore, Kubernetes does not automatically propagate updated secret values to running pods’ environment variables, meaning applications won’t pick up new secret values unless the pods are reloaded ([Secrets store CSI driver vs external secrets in a nutshel](https://www.yuribacciarini.com/secrets-store-csi-driver-vs-external-secrets-in-a-nutshel/#:~:text=Finally%20take%20in%20mind%20that%2C,com%2Fstakater%2FReloader)). This underscores the importance of a solution that **both** updates Kubernetes secrets from external sources and refreshes dependent workloads when those secrets change.  

## Decision

We will use **External Secrets Operator (ESO)** in combination with **Reloader** to manage external secrets in our Kubernetes clusters. This approach was chosen for its simplicity and alignment with our deployment practices. Key advantages of this decision include: 

- **Simple configuration and minimal overhead**: External Secrets Operator runs as a single controller in the cluster, not a per-node daemon, which keeps resource usage low ([Clarity: secrets store CSI driver vs external secrets... what to use? · Issue #478 · external-secrets/external-secrets · GitHub](https://github.com/external-secrets/external-secrets/issues/478#:~:text=One%20of%20the%20differences%20is,and%20save%20resources%20as%20well)). We only need to deploy the operator and its Custom Resources. Reloader is a lightweight add-on that watches for secret changes and triggers pod restarts as needed.  
- **Manifests remain in code (UDS package compatibility)**: Using ESO allows us to define **ExternalSecret** resources in our configuration manifests (e.g., our UDS packages) just like any other Kubernetes object. This means we retain our Infrastructure-as-Code approach — the source-of-truth for what secrets are needed and where they come from stays in our git manifests, with no manual secret injection steps.  
- **Minimal prerequisites (IRSA integration)**: The only upfront requirement is an AWS IAM Role for Service Account (IRSA) or equivalent credentials setup, which grants the operator access to external secret stores (like AWS Secrets Manager). Once that IRSA role is prepared and provided at deploy time, no further external setup is needed in the cluster. We do not need to install complex storage drivers or additional node-level components.  

With External Secrets Operator pulling in the latest secret values and Reloader ensuring pods reload those updates, our cluster will automatically stay up-to-date with externally managed secrets. This decision strikes a balance between operational simplicity and reliability in secret management. 

### Alternatives Considered 

- **External Secrets Operator (ESO) – *Chosen***: ESO natively integrates with external secret managers and was ultimately selected for its ease of use and lightweight footprint. It leverages Kubernetes Custom Resource Definitions to track external secrets and automatically creates/updates standard Kubernetes Secret objects. This means our existing apps can consume secrets as usual, but now those secrets stay in sync with the external source. The operator’s simple deployment (no per-node agents) and compatibility with our manifest-driven workflow made it the preferred choice.  

- **Secrets Store CSI Driver (AWS Secrets CSI)**: We considered Kubernetes Secrets Store CSI Driver with an AWS Secrets Manager provider. This solution was **not chosen** because it introduces additional overhead and complexity. The CSI driver runs as a DaemonSet on every node (along with provider pods), often with elevated privileges ([Secrets store CSI driver vs external secrets in a nutshel](https://www.yuribacciarini.com/secrets-store-csi-driver-vs-external-secrets-in-a-nutshel/#:~:text=,pod)). While it can mount secrets as volumes or create Secrets, using it typically requires modifying application manifests to use CSI volumes or enabling secret syncing. This represents a heavier lift and new moving parts in the cluster. In contrast, ESO provides a more straightforward pull-and-create mechanism for secrets without per-node infrastructure, reducing complexity and resource usage ([Clarity: secrets store CSI driver vs external secrets... what to use? · Issue #478 · external-secrets/external-secrets · GitHub](https://github.com/external-secrets/external-secrets/issues/478#:~:text=One%20of%20the%20differences%20is,and%20save%20resources%20as%20well)).  

- **Manual Secret Management (e.g. scheduled `uds run`)**: Another alternative was to handle external secrets by manually retrieving and applying them to the cluster (for example, running `uds run` on a schedule or during deployments to update secrets). We rejected this approach due to its operational drawbacks. Relying on manual or scheduled updates would require continual human involvement or custom scripting, increasing the chance of delays or errors. There’s a risk that a secret could be updated externally and not reflected in the cluster until the next manual run, potentially causing application failures or security exposure. This method does not scale well and adds operational burden, whereas an operator-based solution automates the process continuously.  

**Security Considerations**:  
Security and compliance were factored into this decision, especially regarding container images and access controls:

- **External Secrets Operator**: The ESO container image is available in trusted repositories (it’s included in Chainguard’s secure image catalog and is also present in IronBank). This means it has been vetted for security vulnerabilities and can meet our organization’s compliance requirements. We will use the approved image and follow best practices (least-privilege IAM role, Kubernetes RBAC restrictions for the operator) to ensure the operator only accesses the secrets it needs.  

- **Reloader**: The Reloader component (e.g., Stakater’s Reloader) is available as a Chainguard image, which provides a high level of supply-chain security. However, it is not currently listed in IronBank’s container catalog. This implies that we may need to get Reloader separately approved or use the Chainguard image with our internal accreditation. We acknowledge this as a minor concern and will mitigate it by tracking Reloader’s image source and updates closely. Notably, Reloader’s functionality is simple (watching for secret/configmap changes and triggering rollouts), and it doesn’t require elevated privileges, which limits its security risk profile.  

**Consequences**:  
Adopting External Secrets Operator and Reloader has several consequences, both positive outcomes and trade-offs:

- **Automated secret rotation**: Our cluster resources will always reflect the latest external secret values. When an external secret (e.g., in AWS Secrets Manager) changes, ESO will quickly sync the new value into the corresponding Kubernetes Secret. This reduces the risk of applications using outdated credentials and improves our security posture by ensuring rotations actually propagate.  

- **Automatic application reloads**: With Reloader in place, any update to a Kubernetes Secret (or ConfigMap) will trigger a rolling restart of pods that reference that secret. Applications will seamlessly pick up new secrets without manual intervention. This greatly simplifies operations — for example, if a certificate or password is rotated, the new value is used by pods within minutes, with no need to orchestrate a manual rollout. We must ensure our workloads handle restarts gracefully, but in exchange we get a more self-healing and up-to-date system.  

- **Operational simplicity**: This solution fits into our existing deployment model (manifests and GitOps). Development teams don’t need to learn new manual processes or volume mounting patterns to use external secrets — they continue to define required secrets in manifests, and the system handles the rest. It offloads the complexity of secret management to the operator, which is its core purpose. 

- **Additional components to manage**: By implementing this decision, we introduce two new components in our clusters (ESO and Reloader). This comes with a small overhead of monitoring these components and keeping them updated. The team will need to include the operator and reloader in our upgrade/testing cycle to ensure they remain compatible with cluster upgrades. However, these components are well-maintained open-source projects, and the burden of running them is low compared to the effort saved in manual secret management.  

- **Compliance trade-off**: Because Reloader is not in IronBank, there is a slight deviation from using only IronBank-approved images. The consequence is that we will either use the Chainguard-provided Reloader image or build our own hardened image. We judge this trade-off acceptable given Reloader’s benefits, but it will be documented and reviewed by our security team. In the future, if an IronBank-certified Reloader becomes available or if ESO introduces a similar reload feature, we can re-evaluate and potentially phase out the separate Reloader component.  

In summary, the decision to use External Secrets Operator with Reloader provides a **secure, automated, and maintainable** way to manage externally sourced secrets. It significantly reduces manual work and the risk of secret drift, at the cost of running two additional lightweight services in the cluster. This trade-off is justified by the improvements in security hygiene and operational efficiency for our Kubernetes environments.

## Consequences

- Update the UDS Base Bundle deployed to clusters to include the External Secrets Operator and Reloader packages.
