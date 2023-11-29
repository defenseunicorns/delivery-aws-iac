# Changelog

## [0.0.11](https://github.com/defenseunicorns/delivery-aws-iac/compare/v0.0.10...v0.0.11) (2023-11-28)


### Features

* migrate lambda module to its own repo ([#375](https://github.com/defenseunicorns/delivery-aws-iac/issues/375)) ([1447362](https://github.com/defenseunicorns/delivery-aws-iac/commit/14473623f34561aaa14940855243f0ee79c88e1c))


### Bug Fixes

* **deps:** update all dependencies ([#382](https://github.com/defenseunicorns/delivery-aws-iac/issues/382)) ([58483e5](https://github.com/defenseunicorns/delivery-aws-iac/commit/58483e5ba53be677329a79314b2af1b91fd4602f))


### Documentation

* ADR 11 for ci testing refactor ([#374](https://github.com/defenseunicorns/delivery-aws-iac/issues/374)) ([f35c424](https://github.com/defenseunicorns/delivery-aws-iac/commit/f35c4244a84b38aedad855f46a36289728495c6c))
* spike/adr for e2e testing ([#354](https://github.com/defenseunicorns/delivery-aws-iac/issues/354)) ([360cc0b](https://github.com/defenseunicorns/delivery-aws-iac/commit/360cc0be575dc002478e881b4cd376516f9314ea))
* update ADR ([#378](https://github.com/defenseunicorns/delivery-aws-iac/issues/378)) ([df4a7ec](https://github.com/defenseunicorns/delivery-aws-iac/commit/df4a7ec2eefd089d4ff267c93c0cbb33c787f50d))


### Miscellaneous Chores

* **deps:** update all dependencies ([#352](https://github.com/defenseunicorns/delivery-aws-iac/issues/352)) ([122308a](https://github.com/defenseunicorns/delivery-aws-iac/commit/122308a1f73f808fe158a255d98d3de4bd5030dd))
* remove uds references ([#376](https://github.com/defenseunicorns/delivery-aws-iac/issues/376)) ([ba9f8b2](https://github.com/defenseunicorns/delivery-aws-iac/commit/ba9f8b2bdc7d88d68e967194f9b94119ebaca855))


### Continuous Integration

* e2e secure test once a week ([#379](https://github.com/defenseunicorns/delivery-aws-iac/issues/379)) ([0a56de6](https://github.com/defenseunicorns/delivery-aws-iac/commit/0a56de6e69bc64b20e41a053393be6b3fab90737))
* fix permissions issues and move release-please to reusable workflow ([#365](https://github.com/defenseunicorns/delivery-aws-iac/issues/365)) ([f847649](https://github.com/defenseunicorns/delivery-aws-iac/commit/f84764990254ceea749651a77f5ee2d7578cdf35))
* make ci flexible ([#372](https://github.com/defenseunicorns/delivery-aws-iac/issues/372)) ([c1aa0e0](https://github.com/defenseunicorns/delivery-aws-iac/commit/c1aa0e06e37190702fc9c1c61809facd18b1af21))
* merge queue testing implementation ([#364](https://github.com/defenseunicorns/delivery-aws-iac/issues/364)) ([9ef9fcf](https://github.com/defenseunicorns/delivery-aws-iac/commit/9ef9fcff49e5bc87397cc2747649df8895562ae8))
* remove asdf install ([#367](https://github.com/defenseunicorns/delivery-aws-iac/issues/367)) ([6b57a1d](https://github.com/defenseunicorns/delivery-aws-iac/commit/6b57a1de742d4713e8729c7befc399ee5e0b8153))
* update renovate window ([#381](https://github.com/defenseunicorns/delivery-aws-iac/issues/381)) ([7c495ac](https://github.com/defenseunicorns/delivery-aws-iac/commit/7c495ac62e3a4710f84bd8ee58a1303fb0b8bab6))

## [0.0.10](https://github.com/defenseunicorns/delivery-aws-iac/compare/v0.0.9...v0.0.10) (2023-09-13)


### Miscellaneous Chores

* **deps:** update all dependencies ([#315](https://github.com/defenseunicorns/delivery-aws-iac/issues/315)) ([ccc71d9](https://github.com/defenseunicorns/delivery-aws-iac/commit/ccc71d9c94ee8aa904a0decb4bb776335dda15e5))
* **deps:** update all dependencies ([#345](https://github.com/defenseunicorns/delivery-aws-iac/issues/345)) ([41e5da0](https://github.com/defenseunicorns/delivery-aws-iac/commit/41e5da049e99e09ed5f65e605f8fc2bf85ef59f1))
* **deps:** update all dependencies ([#349](https://github.com/defenseunicorns/delivery-aws-iac/issues/349)) ([6144bf9](https://github.com/defenseunicorns/delivery-aws-iac/commit/6144bf9b4761648ddcb85620cf60a28aff2bcc54))


### Code Refactoring

* removal of kubectl provider ([#348](https://github.com/defenseunicorns/delivery-aws-iac/issues/348)) ([98ca153](https://github.com/defenseunicorns/delivery-aws-iac/commit/98ca153745879625dc7ab3cbf5816a71678e061b))


### Continuous Integration

* fix some inputs for renovate to monitor properly ([#347](https://github.com/defenseunicorns/delivery-aws-iac/issues/347)) ([bf60547](https://github.com/defenseunicorns/delivery-aws-iac/commit/bf60547b1d206266c030a537baf40cba5acf5ddb))
* refactor for shared workflows ([#346](https://github.com/defenseunicorns/delivery-aws-iac/issues/346)) ([5c4bb84](https://github.com/defenseunicorns/delivery-aws-iac/commit/5c4bb845d1b293d83a2b2657ecf2ec42bb53c312))

## [0.0.9](https://github.com/defenseunicorns/delivery-aws-iac/compare/v0.0.8...v0.0.9) (2023-08-23)


### Features

* update eks module for blueprints v5 migration ([#337](https://github.com/defenseunicorns/delivery-aws-iac/issues/337)) ([2b7e7d5](https://github.com/defenseunicorns/delivery-aws-iac/commit/2b7e7d5f136f6eaa5f1fa74ff0318a26a02eefdb))


### Miscellaneous Chores

* **ci:** Add support for using the merge queue, refactor workflow file names, and add more docs to the workflow files ([#340](https://github.com/defenseunicorns/delivery-aws-iac/issues/340)) ([410ee6c](https://github.com/defenseunicorns/delivery-aws-iac/commit/410ee6ca4c1ba659cfce3b423b64d75793d0a1e5))
* **ci:** Fix typo in merge_group test jobs ([#342](https://github.com/defenseunicorns/delivery-aws-iac/issues/342)) ([cc15c5c](https://github.com/defenseunicorns/delivery-aws-iac/commit/cc15c5c9e85df42b44b3b8797079644bb4118386))

## 0.0.8 (2023-08-16)


### Features

* add password-rotation Lambda module and utilize it in the examples/complete root module ([#311](https://github.com/defenseunicorns/delivery-aws-iac/issues/311)) ([97cfb65](https://github.com/defenseunicorns/delivery-aws-iac/commit/97cfb65254940b0042385ca1f989ffd9853ecfe7))


### Bug Fixes

* add eks 1.27 & gp3 storage class ([#325](https://github.com/defenseunicorns/delivery-aws-iac/issues/325)) ([b4ecfb1](https://github.com/defenseunicorns/delivery-aws-iac/commit/b4ecfb1f2e399419e855fe9eaff871ea9f304219))
* **ci:** Change the parse job in test and update workflows to always use main ([#332](https://github.com/defenseunicorns/delivery-aws-iac/issues/332)) ([2a92fae](https://github.com/defenseunicorns/delivery-aws-iac/commit/2a92fae5cdfd20eaada800e692a76570326aed09))
* remove big bang dependencies ([#325](https://github.com/defenseunicorns/delivery-aws-iac/issues/325)) ([b4ecfb1](https://github.com/defenseunicorns/delivery-aws-iac/commit/b4ecfb1f2e399419e855fe9eaff871ea9f304219))
* stop using spot instances in the example root module ([#329](https://github.com/defenseunicorns/delivery-aws-iac/issues/329)) ([656cee6](https://github.com/defenseunicorns/delivery-aws-iac/commit/656cee66e6d591309745dba287c5b35685db7293))
* upgrade addon versions ([#325](https://github.com/defenseunicorns/delivery-aws-iac/issues/325)) ([b4ecfb1](https://github.com/defenseunicorns/delivery-aws-iac/commit/b4ecfb1f2e399419e855fe9eaff871ea9f304219))


### Documentation

* **adr:** add ADR for how to trigger automated tests ([#321](https://github.com/defenseunicorns/delivery-aws-iac/issues/321)) ([49d1f77](https://github.com/defenseunicorns/delivery-aws-iac/commit/49d1f77ed3c4bd188e0f782b543e0b0d2cbe936d))


### Miscellaneous Chores

* **deps:** enable renovate updates in examples/complete/fixtures.common.tfvars for Zarf, EKS, aws-node-termination-handler, kubernetes autoscaler chart and underlying image, metrics-server, and calico ([#309](https://github.com/defenseunicorns/delivery-aws-iac/issues/309)) ([1e48f68](https://github.com/defenseunicorns/delivery-aws-iac/commit/1e48f68c40c4201eff4b41c6bb146164fa6742c0))
* **deps:** help Renovate get around Checkov's IP block ([#324](https://github.com/defenseunicorns/delivery-aws-iac/issues/324)) ([71f4534](https://github.com/defenseunicorns/delivery-aws-iac/commit/71f4534cb872bab766b818b79745bf5d7fa2358c))
* **deps:** Upgrade aws/aws-sdk-go from v1.44.293 to v1.44.299 ([#305](https://github.com/defenseunicorns/delivery-aws-iac/issues/305)) ([7cfec56](https://github.com/defenseunicorns/delivery-aws-iac/commit/7cfec56cff02a74502296456131d89e2aeaa3c7d))
* **deps:** upgrade awscli from 2.13.0 to 2.13.1 ([#313](https://github.com/defenseunicorns/delivery-aws-iac/issues/313)) ([f4a7cae](https://github.com/defenseunicorns/delivery-aws-iac/commit/f4a7caebefd8338214c2fb606c49a697ce7dc3ee))
* **deps:** upgrade awscli from v2.12.5 to v2.13.0 ([#305](https://github.com/defenseunicorns/delivery-aws-iac/issues/305)) ([7cfec56](https://github.com/defenseunicorns/delivery-aws-iac/commit/7cfec56cff02a74502296456131d89e2aeaa3c7d))
* **deps:** upgrade defenseunicorns/build-harness from 1.7.0 to 1.8.0 ([#313](https://github.com/defenseunicorns/delivery-aws-iac/issues/313)) ([f4a7cae](https://github.com/defenseunicorns/delivery-aws-iac/commit/f4a7caebefd8338214c2fb606c49a697ce7dc3ee))
* **deps:** upgrade defenseunicorns/build-harness from v1.4.2 to v1.7.0 ([#305](https://github.com/defenseunicorns/delivery-aws-iac/issues/305)) ([7cfec56](https://github.com/defenseunicorns/delivery-aws-iac/commit/7cfec56cff02a74502296456131d89e2aeaa3c7d))
* **deps:** upgrade defenseunicorns/zarf from 0.28.1 to 0.28.2 ([#313](https://github.com/defenseunicorns/delivery-aws-iac/issues/313)) ([f4a7cae](https://github.com/defenseunicorns/delivery-aws-iac/commit/f4a7caebefd8338214c2fb606c49a697ce7dc3ee))
* **deps:** upgrade defenseunicorns/zarf from v0.28.0 to v0.28.1 ([#305](https://github.com/defenseunicorns/delivery-aws-iac/issues/305)) ([7cfec56](https://github.com/defenseunicorns/delivery-aws-iac/commit/7cfec56cff02a74502296456131d89e2aeaa3c7d))
* **deps:** upgrade github.com/aws/aws-sdk-go from 1.44.299 to 1.44.301 ([#313](https://github.com/defenseunicorns/delivery-aws-iac/issues/313)) ([f4a7cae](https://github.com/defenseunicorns/delivery-aws-iac/commit/f4a7caebefd8338214c2fb606c49a697ce7dc3ee))
* **deps:** upgrade github.com/defenseunicorns/terraform-aws-eks from 0.0.1-alpha to 0.0.2 ([#313](https://github.com/defenseunicorns/delivery-aws-iac/issues/313)) ([f4a7cae](https://github.com/defenseunicorns/delivery-aws-iac/commit/f4a7caebefd8338214c2fb606c49a697ce7dc3ee))
* **deps:** upgrade github.com/defenseunicorns/terraform-aws-vpc from 0.0.2-alpha to 0.0.2 ([#313](https://github.com/defenseunicorns/delivery-aws-iac/issues/313)) ([f4a7cae](https://github.com/defenseunicorns/delivery-aws-iac/commit/f4a7caebefd8338214c2fb606c49a697ce7dc3ee))
* **deps:** upgrade github.com/terraform-aws-modules/terraform-aws-lambda from 5.0.0 to 5.3.0 ([#313](https://github.com/defenseunicorns/delivery-aws-iac/issues/313)) ([f4a7cae](https://github.com/defenseunicorns/delivery-aws-iac/commit/f4a7caebefd8338214c2fb606c49a697ce7dc3ee))
* **deps:** upgrade golang from 1.20.5 to 1.20.6 ([#313](https://github.com/defenseunicorns/delivery-aws-iac/issues/313)) ([f4a7cae](https://github.com/defenseunicorns/delivery-aws-iac/commit/f4a7caebefd8338214c2fb606c49a697ce7dc3ee))
* **deps:** upgrade gruntwork-ioterratest from v0.43.6 to v0.43.8 ([#305](https://github.com/defenseunicorns/delivery-aws-iac/issues/305)) ([7cfec56](https://github.com/defenseunicorns/delivery-aws-iac/commit/7cfec56cff02a74502296456131d89e2aeaa3c7d))
* **deps:** upgrade renovatebot/pre-commit-hooks from 36.7.0 to 36.10..0 ([#313](https://github.com/defenseunicorns/delivery-aws-iac/issues/313)) ([f4a7cae](https://github.com/defenseunicorns/delivery-aws-iac/commit/f4a7caebefd8338214c2fb606c49a697ce7dc3ee))
* **deps:** upgrade renovatebot/pre-commit-hooks from v35.147.0 to v36.7.0 ([#305](https://github.com/defenseunicorns/delivery-aws-iac/issues/305)) ([7cfec56](https://github.com/defenseunicorns/delivery-aws-iac/commit/7cfec56cff02a74502296456131d89e2aeaa3c7d))
* **deps:** upgrade terraform from 1.5.2 to 1.5.3 ([#313](https://github.com/defenseunicorns/delivery-aws-iac/issues/313)) ([f4a7cae](https://github.com/defenseunicorns/delivery-aws-iac/commit/f4a7caebefd8338214c2fb606c49a697ce7dc3ee))
* release 0.0.8 ([6011188](https://github.com/defenseunicorns/delivery-aws-iac/commit/601118878b7d4ef030fbcdfb3c5dedfa0758b8a4))


### Code Refactoring

* **automation:** refactor parse logic to make it a bit simpler ([#323](https://github.com/defenseunicorns/delivery-aws-iac/issues/323)) ([113758a](https://github.com/defenseunicorns/delivery-aws-iac/commit/113758a2a09ce993cbb85149c976cb1d0fba64b9))
* **automation:** refactor the update-command workflow so that the bulk of the logic is in a reusable action, since it will now be used in 2 different places ([#323](https://github.com/defenseunicorns/delivery-aws-iac/issues/323)) ([113758a](https://github.com/defenseunicorns/delivery-aws-iac/commit/113758a2a09ce993cbb85149c976cb1d0fba64b9))
* **automation:** simplify the if statements now that we aren't trying to run tests on push to main anymore ([#323](https://github.com/defenseunicorns/delivery-aws-iac/issues/323)) ([113758a](https://github.com/defenseunicorns/delivery-aws-iac/commit/113758a2a09ce993cbb85149c976cb1d0fba64b9))
* **pr-automation:** simplify the GitHub context name that the E2E tests use so that we can require them regardless of how they were triggered ([#323](https://github.com/defenseunicorns/delivery-aws-iac/issues/323)) ([113758a](https://github.com/defenseunicorns/delivery-aws-iac/commit/113758a2a09ce993cbb85149c976cb1d0fba64b9))


### Continuous Integration

* **main:** delete the pre-commit-trunk workflow now that we aren't trying to run it on commits to main ([#323](https://github.com/defenseunicorns/delivery-aws-iac/issues/323)) ([113758a](https://github.com/defenseunicorns/delivery-aws-iac/commit/113758a2a09ce993cbb85149c976cb1d0fba64b9))
* **pr-automation:** delete the auto-labeling workflow ([#323](https://github.com/defenseunicorns/delivery-aws-iac/issues/323)) ([113758a](https://github.com/defenseunicorns/delivery-aws-iac/commit/113758a2a09ce993cbb85149c976cb1d0fba64b9))
* **release:** change release-please config to bump patch for pre-1.0.0 minor changes ([#331](https://github.com/defenseunicorns/delivery-aws-iac/issues/331)) ([a556560](https://github.com/defenseunicorns/delivery-aws-iac/commit/a556560f443aa763f4d7449b3558cdf31ffd914b))
* **release:** fix auto-tagging workflow previously released ([#308](https://github.com/defenseunicorns/delivery-aws-iac/issues/308)) ([12310eb](https://github.com/defenseunicorns/delivery-aws-iac/commit/12310eb419c623ddbcf58cdb2f42e43af76381a1))
* **release:** update automated release process to use release-please ([#326](https://github.com/defenseunicorns/delivery-aws-iac/issues/326)) ([bd2cf4d](https://github.com/defenseunicorns/delivery-aws-iac/commit/bd2cf4d49f77b794babbc54e1368a6a47990cc9a))
* **test:** Add ability to run Secure E2E and Insecure E2E tests separately, and only run Insecure test in commercial and Secure test in govcloud ([#333](https://github.com/defenseunicorns/delivery-aws-iac/issues/333)) ([bd2e23a](https://github.com/defenseunicorns/delivery-aws-iac/commit/bd2e23a04f32cbd33cea9e147312dfeeeb644aa1))
* **test:** change commercial primary test region from us-east-1 to us-east-2 ([#313](https://github.com/defenseunicorns/delivery-aws-iac/issues/313)) ([f4a7cae](https://github.com/defenseunicorns/delivery-aws-iac/commit/f4a7caebefd8338214c2fb606c49a697ce7dc3ee))
* **test:** change commercial secondary test region from us-east-2 to us-east-1 ([#313](https://github.com/defenseunicorns/delivery-aws-iac/issues/313)) ([f4a7cae](https://github.com/defenseunicorns/delivery-aws-iac/commit/f4a7caebefd8338214c2fb606c49a697ce7dc3ee))
* **test:** update the auto-test workflow to reflect the decisions documented in ADR 8 ([#323](https://github.com/defenseunicorns/delivery-aws-iac/issues/323)) ([113758a](https://github.com/defenseunicorns/delivery-aws-iac/commit/113758a2a09ce993cbb85149c976cb1d0fba64b9))
