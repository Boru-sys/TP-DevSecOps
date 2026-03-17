#!/usr/bin/env python3

import sys
import requests
import docker


def test_containers_running():
    """Test if all required containers are running"""
    client = docker.from_env()
    required_containers = ["prometheus", "grafana", "jenkins"]

    for container_name in required_containers:
        try:
            container = client.containers.get(container_name)
            assert container.status == "running", f"{container_name} is not running"
            print(f"{container_name} is running")
        except docker.errors.NotFound:
            print(f"{container_name} not found")
            return False
        except AssertionError as e:
            print(str(e))
            return False

    return True


def test_services_health():
    """Test if services are responding"""
    services = {
        "Prometheus": "http://localhost:9090/-/healthy",
        "Grafana": "http://localhost:3000/api/health",
        "Jenkins": "http://localhost:8080/login",
    }

    for service, url in services.items():
        try:
            response = requests.get(url, timeout=5)
            if response.status_code in [200, 401]:  # 401 for auth required
                print(f"{service} is healthy")
            else:
                print(f"{service} returned status {response.status_code}")
                return False
        except requests.exceptions.RequestException as e:
            print(f"{service} is not responding: {e}")
            return False

    return True


def test_prometheus_metrics():
    """Test if Prometheus is collecting metrics"""
    try:
        response = requests.get("http://localhost:9090/api/v1/query?query=up", timeout=5)
        data = response.json()

        if data["status"] == "success" and len(data["data"]["result"]) > 0:
            print("Prometheus is collecting metrics")
            return True
        else:
            print("Prometheus is not collecting metrics")
            return False
    except Exception as e:
        print(f"Failed to query Prometheus: {e}")
        return False


def test_grafana_datasources():
    """Test if Grafana has Prometheus datasource configured"""
    try:
        response = requests.get(
            "http://localhost:3000/api/datasources",
            auth=("admin", "gitops2024"),
            timeout=5,
        )
        datasources = response.json()
        prometheus_configured = any(ds.get("type") == "prometheus" for ds in datasources)

        if prometheus_configured:
            print("Grafana has Prometheus datasource")
            return True
        else:
            print("Grafana missing Prometheus datasource")
            return False
    except Exception as e:
        print(f"Failed to check Grafana datasources: {e}")
        return False


def main():
    """Run all tests"""
    print("Running Infrastructure Tests...\n")

    tests = [
        test_containers_running,
        test_services_health,
        test_prometheus_metrics,
        test_grafana_datasources,
    ]

    results = []

    for test in tests:
        print(f"\nRunning {test.__name__}...")
        results.append(test())

    print("\n" + "=" * 50)

    if all(results):
        print("All tests passed!")
        return 0
    else:
        print("Some tests failed!")
        return 1


if __name__ == "__main__":
    sys.exit(main())

