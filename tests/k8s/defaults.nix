{ config, lib, kubenix, ... }:
with lib; let
  inherit (config.kubernetes.api.resources.pods) pod1;
  inherit (config.kubernetes.api.resources.pods) pod2;
  inherit (config.kubernetes.api.resources.deployments) deployment1;
in
{
  imports = with kubenix.modules; [ test k8s ];

  test = {
    name = "k8s-defaults";
    description = "Simple k8s testing wheter name, apiVersion and kind are preset";
    assertions = [
      {
        message = "Should have label set with resource";
        assertion = pod1.metadata.labels.resource-label == "value";
      }
      {
        message = "Should have default label set with group, version, kind";
        assertion = pod1.metadata.labels.gvk-label == "value";
      }
      {
        message = "Should have conditional annotation set";
        assertion = pod2.metadata.annotations.conditional-annotation == "value";
      }
      {
        message = "Should set default hostname for all Pods";
        assertion = lib.all
          (pod: pod.metadata.labels.matched-by-ref == "value")
          (lib.attrValues config.kubernetes.api.resources.pods);
      }
      {
        message = "Should set default hostname for all Pods";
        assertion = lib.all
          (pod: pod.spec.hostname == "defaultHostName")
          (lib.attrValues config.kubernetes.api.resources.pods);
      }
      {
        message = "Should set replicas to 7 for all deployments";
        assertion = deployment1.spec.replicas == 7;
      }
    ];
  };

  kubernetes.resources.pods.pod1.spec = { };

  kubernetes.resources.pods.pod2 = {
    metadata.labels.custom-label = "value";
    spec = { };
  };

  kubernetes.resources.deployments.deployment1.spec = { };

  kubernetes.api.defaults = [
    {
      resource = "pods";
      default.metadata.labels.resource-label = "value";
    }
    {
      group = "core";
      kind = "Pod";
      version = "v1";
      default.metadata.labels.gvk-label = "value";
    }
    {
      resource = "pods";
      default = { config, ... }: {
        config.metadata.annotations = mkIf (config.metadata.labels ? "custom-label") {
          conditional-annotation = "value";
        };
      };
    }
    {
      resource = "io.k8s.api.core.v1.Pod";
      default = {
        config.metadata.labels.matched-by-ref = "value";
      };
    }
    {
      resource = "io.k8s.api.core.v1.PodSpec";
      group = "core";
      version = "v1";
      kind = "PodSpec";
      default = {
        hostname = "defaultHostName";
      };
    }
    {
      resource = "io.k8s.api.apps.v1.DeploymentSpec";
      group = "apps.k8s.io";
      version = "v1";
      kind = "DeploymentSpec";
      default = {
        replicas = 7;
      };
    }
  ];
}
