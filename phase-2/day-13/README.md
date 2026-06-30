# Day 13

This day covers Ingress and Ingress Controllers for HTTP routing across multiple backend services.

## Concept Overview

Standard Kubernetes Services of type `ClusterIP` are only accessible inside the cluster. While you can expose them externally using `NodePort` or `LoadBalancer` services, these operate at Layer 4 (TCP/UDP). This means each service requires its own external port or expensive cloud load balancer.

To solve this, Kubernetes uses the **Ingress** API. Ingress operates at Layer 7 (HTTP/HTTPS) and allows you to expose multiple internal services through a single external IP address or host, utilizing path-based or host-based routing.

```text
                          [ HTTP Traffic (Port 80) ]
                                      │
                                      ▼
                        [ Ingress Controller (Traefik/Nginx) ]
                         (Evaluates Ingress rules)
                                      │
                 ┌────────────────────┴────────────────────┐
                 │ (Path: /apple)                          │ (Path: /banana)
                 ▼                                         ▼
         [ apple-service ]                         [ banana-service ]
           (Port 5678)                               (Port 5678)
                 │                                         │
                 ▼                                         ▼
         [ apple-web-pod ]                         [ banana-web-pod ]
```

---

## Core Concepts

### Core Components

1. **Ingress Resource:** A set of routing rules (YAML manifest) that maps HTTP hosts and paths to internal Kubernetes Services.
2. **Ingress Controller:** The actual reverse proxy and load balancer running in the cluster (such as NGINX, Traefik, HAProxy, or Envoy). The controller watches the API server for Ingress resources and dynamically updates its configuration to route traffic.
    *(Note: Unlike other controllers in the control plane, the Ingress Controller is not started automatically. You must deploy it as a cluster add-on).*

---

### Routing Types

#### 1. Path-Based Routing

Directs traffic based on the URL path.

* `http://my-site.com/apple` -> routes to `apple-service`
* `http://my-site.com/banana` -> routes to `banana-service`

#### 2. Host-Based Routing (Virtual Hosting)

Directs traffic based on the HTTP `Host` header.

* `http://apple.my-site.com` -> routes to `apple-service`
* `http://banana.my-site.com` -> routes to `banana-service`

---

### Path Types

When defining rules, you specify how the controller matches URL paths:

* **Exact:** Matches the URL path exactly, case-sensitively (e.g., `/apple` only matches `/apple`, not `/apple/index.html`).
* **Prefix:** Matches based on a URL path prefix split by `/` (e.g., `/apple` matches `/apple/v1` and `/apple/v2/image.png`).
* **ImplementationSpecific:** The matching logic depends on the specific Ingress Controller being used.

---

## Checklist

* [ ] Verify that an Ingress Controller is running in the cluster.
* [ ] Deploy two backend web services (Apple and Banana).
* [ ] Create an Ingress resource with path-based routing rules.
* [ ] Configure local DNS translation using the `/etc/hosts` file.
* [ ] Validate HTTP routing paths using `curl`.

---

## Lab

In this lab, you will deploy two simple backend web applications, configure a Traefik or NGINX Ingress resource to route traffic between them based on URL paths, and validate the setup using curl.

### Steps

1. **Create the Namespace:**
    Apply the namespace manifest:

    ```bash
    kubectl apply -f phase-2/day-13/manifests/01-namespace.yaml
    ```

2. **Deploy the Backend Web Applications:**
    We will deploy two separate backend pods using a simple echo server image (which prints the name of the app to the screen) and expose them via services:

    ```bash
    kubectl apply -f phase-2/day-13/manifests/02-deploy-web-apple.yaml
    kubectl apply -f phase-2/day-13/manifests/03-deploy-web-banana.yaml
    ```

    Verify the pods are running and exposed:

    ```bash
    kubectl get pods,svc -n ingress-lab
    ```

3. **Deploy the Ingress Resource:**
    Apply the Ingress manifest. This file defines paths `/apple` and `/banana` mapping to their respective backend services on port `5678`:

    ```bash
    kubectl apply -f phase-2/day-13/manifests/04-ingress-routing.yaml
    ```

    Verify the Ingress resource was created successfully:

    ```bash
    kubectl get ingress -n ingress-lab
    ```

    *Expected Outcome:* You should see the Ingress named `web-ingress`. After 30 to 60 seconds, the `ADDRESS` field should populate with the IP address of your local cluster (e.g., `127.0.0.1` or the IP of your node).

4. **Validate Path Routing:**
    Because Ingress controllers route traffic using the HTTP `Host` header inside the request, you do not need to configure local DNS. You can query the Ingress controller directly using its IP address (or `localhost` if utilizing port forwarding or a proxy tunnel) and manually inject the `Host` header.

    * Find the Ingress IP:

        ```bash
        kubectl get ingress -n ingress-lab
        ```

    * **Test Apple Path:**

        ```bash
        curl -H "Host: app.example.com" http://<ingress-ip-or-localhost>/apple
        ```

        *Expected Output:* `apple`
    * **Test Banana Path:**

        ```bash
        curl -H "Host: app.example.com" http://<ingress-ip-or-localhost>/banana
        ```

        *Expected Output:* `banana`
    * **Test Invalid Path:**

        ```bash
        curl -I -H "Host: app.example.com" http://<ingress-ip-or-localhost>/invalid
        ```

        *Expected Output:* `HTTP/1.1 404 Not Found` (returned by the Ingress controller default backend).

5. **Clean Up:**
    Delete the namespace to clean up all pods, services, and routing rules:

    ```bash
    kubectl delete namespace ingress-lab
    ```

---

[Back to main README.md](../../README.md)
