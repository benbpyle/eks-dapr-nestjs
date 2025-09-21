#!/bin/bash

# Delete All Resources Script
# This script removes all resources created by the deploy.sh script

set -e

# Configuration
CLUSTER_NAME="dapr-demo"
REGION="us-west-2"
NAMESPACE="dapr-services"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored status messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if cluster exists
cluster_exists() {
    eksctl get cluster --name "$CLUSTER_NAME" --region "$REGION" &> /dev/null
}

main() {
    echo "=========================================="
    echo "    K8s + Dapr + Datadog Cleanup Script"
    echo "=========================================="
    echo ""

    # Check if cluster exists
    if ! cluster_exists; then
        print_warning "Cluster '$CLUSTER_NAME' does not exist in region '$REGION'"
        exit 0
    fi

    # Step 1: Delete application services
    print_status "Step 1: Deleting application services..."
    kubectl delete --ignore-not-found=true -f kubernetes/services/ || print_warning "Some services may not exist"
    print_success "Application services deleted"

    # Step 2: Delete Dapr components
    print_status "Step 2: Deleting Dapr components..."
    kubectl delete --ignore-not-found=true -f dapr-components/ || print_warning "Some Dapr components may not exist"
    kubectl delete component --all -n "$NAMESPACE" --ignore-not-found=true || print_warning "No components to delete in namespace"
    print_success "Dapr components deleted"

    # Step 3: Delete namespace
    print_status "Step 3: Deleting application namespace..."
    kubectl delete namespace "$NAMESPACE" --ignore-not-found=true || print_warning "Namespace may not exist"
    print_success "Application namespace deleted"

    # Step 4: Delete ingress resources
    print_status "Step 4: Deleting ingress resources..."
    kubectl delete --ignore-not-found=true -f kubernetes/ingress/ || print_warning "Ingress resources may not exist"
    print_success "Ingress resources deleted"

    # Step 5: Uninstall AWS Load Balancer Controller
    print_status "Step 5: Uninstalling AWS Load Balancer Controller..."
    helm uninstall aws-load-balancer-controller -n kube-system || print_warning "AWS Load Balancer Controller may not be installed"
    print_success "AWS Load Balancer Controller uninstalled"

    # Step 6: Uninstall Datadog Operator
    print_status "Step 6: Uninstalling Datadog Operator..."
    helm uninstall datadog-operator -n datadog-operator || print_warning "Datadog Operator may not be installed"
    kubectl delete namespace datadog-operator --ignore-not-found=true
    print_success "Datadog Operator uninstalled"

    # Step 7: Uninstall Dapr
    print_status "Step 7: Uninstalling Dapr..."
    dapr uninstall -k || print_warning "Dapr may not be installed"
    kubectl delete namespace dapr-system --ignore-not-found=true
    print_success "Dapr uninstalled"

    # Step 8: Delete EKS cluster
    print_status "Step 8: Deleting EKS cluster..."
    print_warning "This will delete the entire EKS cluster '$CLUSTER_NAME'"
    read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deleting cluster '$CLUSTER_NAME'..."
        eksctl delete cluster --name "$CLUSTER_NAME" --region "$REGION"
        print_success "EKS cluster deleted"
    else
        print_warning "Cluster deletion cancelled"
        print_status "To delete the cluster manually, run:"
        echo "  eksctl delete cluster --name $CLUSTER_NAME --region $REGION"
    fi

    # Step 9: Clean up ECR repositories (optional)
    print_status "Step 9: Cleaning up ECR repositories..."
    read -p "Do you want to delete ECR repositories? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deleting ECR repositories..."
        aws ecr-public delete-repository --region us-east-1 --repository-name dapr-comms --force || print_warning "Repository may not exist"
        aws ecr-public delete-repository --region us-east-1 --repository-name dapr-api --force || print_warning "Repository may not exist"
        print_success "ECR repositories deleted"
    else
        print_warning "ECR repository cleanup skipped"
        print_status "To delete repositories manually, run:"
        echo "  aws ecr-public delete-repository --region us-east-1 --repository-name dapr-comms --force"
        echo "  aws ecr-public delete-repository --region us-east-1 --repository-name dapr-api --force"
    fi

    echo ""
    echo "=========================================="
    print_success "Cleanup completed!"
    echo "=========================================="
}

# Run the main function
main "$@"
