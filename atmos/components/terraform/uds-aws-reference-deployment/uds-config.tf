resource "local_file" "test_uds_config" {
  filename = "./ignore/test-uds-config.yaml"
  content  = jsonencode(module.uds_core)
}
locals {
  uds_config                   = module.uds_core.uds_core_properties.uds_config
  uds_sensitive_config         = module.uds_core.uds_core_sensitive_properties.uds_config
  istio_admin_gw_subnets       = [for subnet in module.private_vpc.vpc_properties.reserved_ips_by_service.istio_admin_gateway : subnet.subnet_id]
  istio_admin_gw_ips           = [for subnet in module.private_vpc.vpc_properties.reserved_ips_by_service.istio_admin_gateway : subnet.reserved_ip]
  istio_tenant_gw_subnets      = [for subnet in module.private_vpc.vpc_properties.reserved_ips_by_service.istio_tenant_gateway : subnet.subnet_id]
  istio_tenant_gw_ips          = [for subnet in module.private_vpc.vpc_properties.reserved_ips_by_service.istio_tenant_gateway : subnet.reserved_ip]
  istio_passthrough_gw_subnets = [for subnet in module.private_vpc.vpc_properties.reserved_ips_by_service.istio_passthrough_gateway : subnet.subnet_id]
  istio_passthrough_gw_ips     = [for subnet in module.private_vpc.vpc_properties.reserved_ips_by_service.istio_passthrough_gateway : subnet.reserved_ip]
}

resource "local_sensitive_file" "uds_config" {
  filename = "./ignore/uds-config.yaml"
  //filename = "${local.uds_core_config.config_output_path}/${local.uds_core_config.config_output_file_name}"
  content = <<EOY
variables:
  core:
    ISTIOD_ADMIN_GW_SVC_ANNOTATIONS:
      service.beta.kubernetes.io/aws-load-balancer-type: "internal"
      service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"
      service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
      service.beta.kubernetes.io/aws-load-balancer-attributes: "load_balancing.cross_zone.enabled=true"
      service.beta.kubernetes.io/aws-load-balancer-subnets: "${join(",", local.istio_admin_gw_subnets)}"
      service.beta.kubernetes.io/aws-load-balancer-private-ipv4-addresses: "${join(",", local.istio_admin_gw_ips)}"
    ISTIOD_TENANT_GW_SVC_ANNOTATIONS:
      service.beta.kubernetes.io/aws-load-balancer-type: "internal"
      service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"
      service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
      service.beta.kubernetes.io/aws-load-balancer-attributes: "load_balancing.cross_zone.enabled=true"
      service.beta.kubernetes.io/aws-load-balancer-subnets: "${join(",", local.istio_tenant_gw_subnets)}"
      service.beta.kubernetes.io/aws-load-balancer-private-ipv4-addresses: "${join(",", local.istio_tenant_gw_ips)}"
    ISTIOD_PASSTHRU_GW_SVC_ANNOTATIONS:
      service.beta.kubernetes.io/aws-load-balancer-type: "internal"
      service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"
      service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
      service.beta.kubernetes.io/aws-load-balancer-attributes: "load_balancing.cross_zone.enabled=true"
      service.beta.kubernetes.io/aws-load-balancer-subnets: "${join(",", local.istio_passthrough_gw_subnets)}"
      service.beta.kubernetes.io/aws-load-balancer-private-ipv4-addresses: "${join(",", local.istio_passthrough_gw_ips)}"
    ISTIOD_AUTOSCALE_MIN: "${local.uds_config.core.istiod_autoscale_min}"
    ISTIOD_AUTOSCALE_MAX: "${local.uds_config.core.istiod_autoscale_max}"
    KC_DB_PASSWORD: "${local.uds_sensitive_config.kc_db_password}"
    KC_DB_HOST: "${local.uds_config.core.kc_db_host}"
    VELERO_ROLE_ARN: "${local.uds_config.core.velero_role_arn}"
    # https://github.com/vmware-tanzu/velero-plugin-for-aws/blob/main/backupstoragelocation.md
    VELERO_BACKUP_STORAGE_LOCATION:
      - name: default
        provider: aws
        bucket: "${local.uds_config.core.velero_backup_storage_location_bucket.bucket}"
        config:
          region: "${module.mission_init.region}"
          kmsKeyId: "${local.uds_config.core.velero_backup_storage_location_bucket.config.kmsKeyId}"
    # https://github.com/vmware-tanzu/velero-plugin-for-aws/blob/main/volumesnapshotlocation.md
    VELERO_VOLUME_SNAPSHOT_LOCATION:
      - name: default
        provider: aws
        config:
          region: "${module.mission_init.region}"
    LOKI_BACKEND_PVC_SIZE: "${local.uds_config.core.loki_backend_pvc_size}"
    LOKI_WRITE_PVC_SIZE: "${local.uds_config.core.loki_write_pvc_size}"
    LOKI_S3_REGION: "${module.mission_init.region}"
    %{~for bucket, value in local.uds_config.core.loki_buckets~}
    ${upper(replace(bucket, "-", "_"))}_BUCKET: "${value.s3_bucket_id}"
    %{~endfor~}
    LOKI_S3_ROLE_ARN: "${local.uds_config.core.loki_s3_role_arn}"
    PROMETHEUS_PVC_SIZE: "${local.uds_config.core.prometheus_pvc_size}"
  zarf-init-s3-backend:
    registry_pvc_enabled: "false"
    registry_hpa_min: "2"
    registry_service_account_name: "docker-registry-sa"
    registry_create_service_account: "true"
    registry_service_account_annotations: "eks.amazonaws.com/role-arn: ${local.uds_config["zarf-init-s3-backend"].registry_irsa_role_arn}"
    registry_extra_envs: |
      - name: REGISTRY_STORAGE
        value: s3
      - name: REGISTRY_STORAGE_S3_REGION
        value: "${module.mission_init.region}"
      - name: REGISTRY_STORAGE_S3_BUCKET
        value: "${local.uds_config["zarf-init-s3-backend"].registry_storage_s3_bucket}"
    REGISTRY_HPA_AUTO_SIZE: "true"
    REGISTRY_AFFINITY_CUSTOM: |
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                  - key: app
                    operator: In
                    values:
                      - docker-registry
              topologyKey: kubernetes.io/hostname
    REGISTRY_TOLERATIONS: |
      - effect: NoSchedule
        key: dedicated
        operator: Exists
  storageclass:
    EBS_EXTRA_PARAMETERS: |
      tagSpecification_1: "NamespaceAndId={{ .PVCNamespace }}-${lower(local.deployment_properties.deploy_id)}"
      iopsPerGB: "500"
      allowAutoIOPSPerGBIncrease: "true"
      throughput: "1000"
EOY
}
