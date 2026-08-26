# Tanzu GemFire Management and Monitoring Tools
Internally, Tanzu GemFire exposes its management and monitoring surface through Java MBeans (specifically MXBeans), which any JMX-compliant client can consume. On top of that foundation, GemFire provides several tools: the `gfsh` command-line interface (the primary administrative tool), the Tanzu GemFire Management Console (GMC) (the browser-based operations console), a Prometheus metrics endpoint on each member, a management REST API, and out-of-the-box integration for observability.

## 

## gfsh Command-Line Tool
The GemFire Shell (`gfsh`) is the recommended command-line interface for configuring, managing, and monitoring a cluster. It lets you:

* Start and stop locators and cache servers.  
* Create, alter, or destroy regions.  
* Deploy and manage application JARs.  
* Execute user-defined functions.  
* Manage disk stores and perform data import and export.  
* Monitor members and system metrics.  
* Save and manage shared cluster configurations.

`gfsh` runs as an interactive shell or is invoked from the OS command line, and it supports scripting for automation. It can manage a remote cluster over HTTP or HTTPS, or connect to a JMX Manager member for JMX-based commands. With shared cluster configuration, `gfsh` maintains reusable settings that locators store and synchronize across the cluster (for example, `cluster.xml` and `cluster.properties`). More information:

* [Running gfsh Commands on the OS Command Line](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-gemfire/10-3/gf/tools_modules-gfsh-os_command_line_execution.html)  
* [Using gfsh to Manage a Remote Cluster Over HTTP or HTTPS](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-gemfire/10-3/gf/configuring-cluster_config-gfsh_remote.html)  
* [Creating and Running gfsh Command Scripts](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-gemfire/10-3/gf/tools_modules-gfsh-command_scripting.html)

## Tanzu GemFire Management Console
The Tanzu GemFire Management Console is a browser-based console that streamlines day-to-day operations and provides visual insight across your GemFire estate. It is delivered as a standalone application: a JAR file (JDK 11, 17, or 21) or an OCI container image, that runs alongside your clusters rather than as part of them. It is not a gfsh command, and it can manage an entire fleet of clusters, including multi-site (WAN) topologies, from a single interface.

**Operations and management (write) capabilities**

* Monitor and manage multiple clusters, with a real-time multi-site topology view.  
* Create and configure regions; deploy or remove JARs; manage disk stores.  
* Execute functions and manage WAN gateway senders and receivers.  
* Explore and query data with the built-in Data Explorer (run OQL, inspect entries, and copy data between clusters).  
* Run commands through a built-in web-based `gfsh`.  
* Search and download member logs (see the note under Logging below).

**Monitoring and observability (Tanzu GemFire 10.2 and 10.3)**  
GMC drives its monitoring dashboards from Prometheus rather than by proxying metrics itself. The relevant 10.2 and 10.3 behavior:

* **Metrics source.** Each member (locator and server) exposes its Prometheus metrics at the `/metrics` path on its HTTP service port (`http-service-port`, default 7070). This replaced the earlier per-member "metrics port" model used in 10.1 and earlier. Metric names are the GemFire statistics prefixed with `gemfire_` (for example, `gemfire_gets`).  
* **Enablement.** The endpoint is served only when the member's HTTP service is running: `enable-management-rest-service` on locators (default `true`) and `--start-rest-api` on servers (default `false`, so it must be enabled explicitly). Per-member emission is controlled with `gemfire.prometheus.metrics.emission` (`Default`, `All`, or `None`).  
* **Prometheus, embedded or external.** GMC can auto-start an embedded Prometheus server (OVA and OCI distributions only), or connect to an external, organization-managed Prometheus. When GMC is used for monitoring and the member metrics endpoints are secured (security manager and/or TLS), external Prometheus scraping requests are routed through GMC, which acts as a proxy to satisfy those security and connection constraints.  
* **Real-time-only mode.** Metrics can also be viewed directly in the console without a Prometheus server, retaining up to 60 minutes of recent data. This is useful for lightweight, live visibility.  
* **Retention and dashboards.** With Prometheus, the console presents a historical window of up to seven days (embedded default). Prometheus is the time-series store, so you can attach Grafana to the same Prometheus for custom, enterprise-wide dashboards.  
* **Graphs.** The Monitoring tab organizes metrics into Data (throughput and latencies including P95 and P99, cache hit ratio, queries, async event queues), Cluster (memory, disk utilization, CPU, client connections), and WAN Gateway (receiver throughput and sender queues).

The console is ideal for both routine operations and troubleshooting, providing an intuitive experience for administrators. More information on GMC refer: [Tanzu Management Console](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-gemfire-management-console/1-4/gf-mc/index.html)

**Logging**   
GMC's Logs tab lets you view and download logs and statistics for the locators and servers of a connected cluster, with filtering by date range and log level. Note that this tab is intended for development and troubleshooting and may be insufficient for trailing production logs. The logs themselves live on the member nodes, and GMC reads them on demand rather than aggregating or retaining them. For production, forward member logs to an enterprise logging platform. 

**Authentication modes**  
GMC supports NONE (Developer Mode), OAuth2, LDAP (including LDAP over TLS/SSL), and SAML for multi-user access.  
More information on GMC refer to the [Product Documentation](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-gemfire-management-console/1-4/gf-mc/index.html)

