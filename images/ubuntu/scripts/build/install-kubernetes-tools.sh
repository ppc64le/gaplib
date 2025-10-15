#!/bin/bash -e
################################################################################
##  File:  install-kubernetes-tools.sh
##  Desc:  Installs kubectl, helm, kustomize
##  Supply chain security: KIND, minikube - checksum validation
################################################################################

# Source the helpers for use with the script
# shellcheck disable=SC1091
source "$HELPER_SCRIPTS"/install.sh

# Set architecture-specific variables using a case statement for clarity
case "$ARCH" in
    "x86_64")
        package_arch="amd64"
        ;;
    "ppc64le" | "s390x" | *)
        package_arch="$ARCH"
        ;;
esac

if [[ "$ARCH" == "ppc64le" || "$ARCH" == "s390x" ]]; then 
    export version="latest"
    install_dpkgs golang
    sudo go install sigs.k8s.io/kind@$version # v0.22.0
    # shellcheck disable=SC2046
    sudo cp $(sudo go env GOPATH)/bin/kind /usr/local/bin/
    kind version
else
    # Download KIND
    kind_url=$(resolve_github_release_asset_url "kubernetes-sigs/kind" "endswith(\"kind-linux-${package_arch}\")" "latest")
    kind_binary_path=$(download_with_retry "${kind_url}")
    
    # Supply chain security - KIND
    kind_external_hash=$(get_checksum_from_url "${kind_url}.sha256sum" "kind-linux-${package_arch}" "SHA256")
    use_checksum_comparison "${kind_binary_path}" "${kind_external_hash}"
    
    # Install KIND
    install "${kind_binary_path}" /usr/local/bin/kind
fi
    
# Install kubectl
    
# Ensure keyrings directory exists only if it doesn't already
[ -d /etc/apt/keyrings ] || sudo mkdir -p -m 755 /etc/apt/keyrings
    
kubectl_minor_version=$(curl -fsSL --retry 5 --retry-delay 10 "https://dl.k8s.io/release/stable.txt" | cut -d'.' -f1,2 )
    
# Download and validate GPG key
key_url="https://pkgs.k8s.io/core:/stable:/$kubectl_minor_version/deb/Release.key"
if curl -fsSL --retry 5 --retry-delay 10 -A "Mozilla/5.0" "$key_url" | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg; then
    echo "Key downloaded and stored successfully."
else
    echo "Failed to download valid GPG key from: $key_url"
    exit 1
fi
    
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/'"$kubectl_minor_version"'/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
update_dpkgs
install_dpkgs kubectl
rm -f /etc/apt/sources.list.d/kubernetes.list
    
# Install Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
    
    
# Download and install minikube
minikube_version="latest"
minikube_binary_path=$(download_with_retry "https://storage.googleapis.com/minikube/releases/${minikube_version}/minikube-linux-${package_arch}")
    
# Supply chain security - Minikube
minikube_hash=$(get_checksum_from_github_release "kubernetes/minikube" "linux-${package_arch}" "${minikube_version}" "SHA256")
use_checksum_comparison "${minikube_binary_path}" "${minikube_hash}"
    
install "${minikube_binary_path}" /usr/local/bin/minikube
    
# Install kustomize
download_url="https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"
curl -fsSL "$download_url" | bash
mv kustomize /usr/local/bin
