# Tanzu GemFire Locators
A Tanzu GemFire Locator is a lightweight process that provides system coordination. It allows new members (servers, other locators, and clients) to discover the existing members of a cluster, and it provides load-balancing information that steers client connections to servers.  
A Locator performs two core functions, each handled by a concurrent service running inside the same process:

* **Peer Locator.** Handles cluster member discovery. It helps new servers and locators find and join the distributed system, and it maintains the membership list and a consistent, shared view of the cluster.  
* **Server Locator.** Handles client connection routing. It directs clients to the most suitable (typically least-loaded) cache server, enabling client-side load balancing and high availability for client-to-server connections.

**Locators and network-partition ("split-brain") protection**

Running two or more locators removes the Locator tier as a single point of failure for discovery and coordination, but it is not, by itself, what prevents a split-brain. Split-brain protection is provided separately by GemFire's network-partition detection, which is enabled by default (`enable-network-partition-detection = true`) and is required when partitioned or persistent regions are in use. Under this mechanism, the oldest member (preferentially a Locator) acts as the membership coordinator, and each member contributes a weight to quorum calculations (a Locator weighs 3, a cache server weighs 10, with the lead server weighing 15). If 51 percent or more of the total member weight is lost in a single membership-view change, a network partition is declared and the losing side shuts itself down to preserve consistency. Deploying multiple locators (and at least three cache servers) is what gives this weighting enough members to make a correct, deterministic decision.  
For more details refer to the [official documentation](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-gemfire/10-1/gf/managing-network_partitioning-membership_coordinators_lead_members_and_weighting.html).

**Recommendations for deploying Locators**

* **Minimum of two locators, one per AZ.** This removes the single point of failure for membership and client discovery, and provides the coordinator redundancy the partition-detection logic relies on.  
* **Run locators on separate VMs from cache servers.** Cache servers can experience long garbage-collection pauses under heavy data load; isolating locators ensures such a pause cannot stall the coordinator and trigger cluster-wide membership timeouts.  
* **WAN environments.** Locators discover the locators of remote clusters across the WAN. Low, stable latency on these links is important for reliable multi-site discovery and replication.

By acting as the discovery, coordination, and client-routing layer, the Locator forms the backbone of a cluster's connectivity. A well-configured locator topology keeps the distributed system connected, balanced, and resilient as it scales across zones, regions, and data centers.
