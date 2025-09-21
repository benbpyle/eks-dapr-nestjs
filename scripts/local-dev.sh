#!/bin/bash

# Local Development Script for Dapr Services
# This script helps with local development using Docker Compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Function to check if Docker is running
check_docker() {
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Function to show service status
show_status() {
    print_status "Service Status:"
    echo ""
    echo "🦀 Rust Comms Service:"
    echo "   URL: http://localhost:8080"
    echo "   Health: http://localhost:8080/health"
    echo "   Dapr: http://localhost:3500"
    echo ""
    echo "🟢 Node.js Greeter Service:"
    echo "   URL: http://localhost:3000"
    echo "   Health: http://localhost:3000/health"
    echo "   Dapr: http://localhost:3501"
    echo ""
    echo "🔴 Redis:"
    echo "   URL: localhost:6379"
    echo ""
    echo "🔷 Dapr Placement:"
    echo "   URL: localhost:50006"
    echo ""
}

# Function to test services
test_services() {
    print_status "Testing services..."

    # Wait for services to be ready
    print_status "Waiting for services to be healthy..."
    sleep 10

    # Test health endpoints
    print_status "Testing health endpoints..."

    if curl -f http://localhost:8080/health &> /dev/null; then
        print_success "✅ Rust service health check passed"
    else
        print_error "❌ Rust service health check failed"
    fi

    if curl -f http://localhost:3000/health &> /dev/null; then
        print_success "✅ Node.js service health check passed"
    else
        print_error "❌ Node.js service health check failed"
    fi

    # Test main endpoint
    print_status "Testing main endpoint..."
    if response=$(curl -s "http://localhost:8080/greet?name=LocalTest" 2>/dev/null); then
        print_success "✅ Main endpoint test passed: $response"
    else
        print_error "❌ Main endpoint test failed"
    fi
}

# Main function
case "${1:-help}" in
    "up"|"start")
        print_status "Starting local development environment..."
        check_docker

        # Build and start services
        docker-compose up --build -d

        show_status

        print_status "Waiting for services to start..."
        sleep 15

        test_services

        print_success "Local development environment is ready! 🚀"
        echo ""
        print_status "Try these commands:"
        echo "  curl 'http://localhost:8080/greet?name=World'"
        echo "  curl http://localhost:8080/health"
        echo "  curl http://localhost:3000/health"
        echo ""
        print_status "View logs with:"
        echo "  docker-compose logs -f"
        echo ""
        print_status "Stop with:"
        echo "  ./scripts/local-dev.sh down"
        ;;

    "down"|"stop")
        print_status "Stopping local development environment..."
        docker-compose down -v
        print_success "Local development environment stopped!"
        ;;

    "logs")
        docker-compose logs -f
        ;;

    "test")
        test_services
        ;;

    "status")
        show_status
        docker-compose ps
        ;;

    "clean")
        print_warning "Cleaning up all containers and volumes..."
        docker-compose down -v --remove-orphans
        docker system prune -f
        print_success "Cleanup completed!"
        ;;

    "rebuild")
        print_status "Rebuilding services..."
        docker-compose down -v
        docker-compose build --no-cache
        docker-compose up -d
        sleep 15
        test_services
        print_success "Rebuild completed!"
        ;;

    "help"|*)
        echo "Local Development Script for Dapr Services"
        echo ""
        echo "Usage: $0 {command}"
        echo ""
        echo "Commands:"
        echo "  up/start    - Start local development environment"
        echo "  down/stop   - Stop local development environment"
        echo "  logs        - Show service logs"
        echo "  test        - Test service endpoints"
        echo "  status      - Show service status"
        echo "  clean       - Clean up containers and volumes"
        echo "  rebuild     - Rebuild and restart services"
        echo "  help        - Show this help message"
        echo ""
        echo "Quick start:"
        echo "  $0 up"
        echo "  curl 'http://localhost:8080/greet?name=World'"
        ;;
esac
