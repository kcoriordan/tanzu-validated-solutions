# Tanzu GemFire Logging
Tanzu GemFire uses Apache Log4j 2 as its logging framework. Log4j 2 provides a flexible, high-performance logging system that supports advanced configuration and centralized log management. It has two main components:

* **Log4j 2 API:** the front-end logging API used by all Tanzu GemFire classes to generate log statements.  
* **Log4j 2 Core:** the backend implementation that processes and outputs log messages.

On the Core backend, GemFire runs three custom appenders: `GeodeConsole` (console output), `GeodeLogWriter` (the standard member log files, and a security variant when `security="true"`), and `GeodeAlert` (alerts that are federated to the JMX management and monitoring system, and surfaced in the Management Console).  
The front-end API can be routed to any supported Log4j 2 backend. Tanzu GemFire 10.3 has been tested with Log4j 2.18.0 and requires these core JARs in the classpath:

* `log4j-api-2.18.0.jar`  
* `log4j-core-2.18.0.jar`

Both JARs are included under `&lt;path-to-product&gt;/lib` and are bundled within the `*-dependencies.jar` convenience libraries.

If your own application or a third-party library uses a different front-end logging API, add the matching Log4j 2 bridge, binding, or adapter JAR so that those messages are also routed to Log4j 2:

* Commons Logging: `log4j-jcl-2.18.0.jar` (Commons Logging Bridge)  
* SLF4J: `log4j-slf4j-impl-2.18.0.jar` (SLF4J Binding)  
* java.util.logging: `log4j-jul-2.18.0.jar` (JUL Adapter)

All three are included in the full Log4j 2.18.0 distribution. For more examples, see the Apache Log4j 2 Logging Services page ([https://logging.apache.org/log4j/2.x/](https://logging.apache.org/log4j/2.x/)) and the Log4j 2 FAQ ([https://logging.apache.org/log4j/2.x/faq.html](https://logging.apache.org/log4j/2.x/faq.html)).

## Configuring Logging
Logging can be configured using:

* The member's `gemfire.properties` file.  
* At startup, using gfsh (for example, the `--log-level` option).  
* Dynamically, using the `alter runtime` command (for example, `alter runtime --log-level=`).

**Recommended setup:**

* Run a time synchronization service such as NTP on all GemFire hosts to ensure consistent timestamps across members. Synchronized clocks are the only way to accurately merge and correlate log messages from different hosts.  
* Use a central log management platform (for example, rsyslog, or VCF Operations for Logs (formerly VMware Aria Operations for Logs/vRealize Log Insight)) to collect and monitor warnings and errors.  
* Configure each member to log to its own file for easier debugging and log correlation.

### Default Logging Properties
The following are the default GemFire logging properties:

| Property | Description |
| ----- | ----- |
| log-level | Sets the verbosity of log messages. Supported values (case-insensitive): `none`, `severe`, `error`, `warning`, `info`, `config`, `fine`, `finer`, `finest`, `all`. The default is `config`. For general troubleshooting, use `config` or higher. Use `fine` or lower only for deep debugging, because verbose levels can affect performance. |
| log-file | Specifies the output log file name (relative or absolute path). When a member is started with gfsh and `log-file` is not set, output defaults to `working-directory/&lt;member-name&gt;.log` (for example, `server-name.log` for servers and `locator-name.log` for locators).  |
| log-file-size-limit | Maximum size (in MB) of a single log file. When the limit is exceeded, logs roll over to a new file. A value of `0` means no size limit (a single, non-rolling log file). |
| log-disk-space-limit | Total disk space (in MB) allocated for all rolled log files. When the limit is reached, the oldest rolled files are deleted first. A value of `0` disables the limit. |

Example default configuration:

```
# Default gemfire.properties log file settings
log-level=config
log-file=
log-file-size-limit=0
log-disk-space-limit=0
```

### gfsh Logging
gfsh is the administrative client, not a cluster member. It runs as a separate process on a workstation, jump host, or automation runner, and connects to the cluster through a locator and, for management and monitoring commands, a JMX Manager member. Its logging records the client side of a session: the commands issued, the connection and authentication activity to the locator, JMX Manager, or HTTP management endpoint, and the stack traces of any commands that fail. This is distinct from, and complementary to, the member logs, which record only cluster-side behavior.

gfsh session logging is deactivated by default, because the shell is interactive and typically short-lived. Enable it when the client side is what you need to examine: diagnosing why gfsh cannot connect to or authenticate with a secured or TLS-enabled JMX Manager or HTTP manager, debugging gfsh scripts run non-interactively in automation or CI/CD pipelines, or keeping a record of the administrative commands issued from a shell. For ad hoc troubleshooting within a running shell, the `debug on` command activates verbose shell output for the current session without setting a system property.  
To enable file logging, set the `gfsh.log-level` system property before starting gfsh, using one of `severe`, `warning`, `info`, `config`, `fine`, `finer`, or `finest`:

```shell
export JAVA_ARGS=-Dgfsh.log-level=[severe|warning|info|config|fine|finer|finest]
```

gfsh writes its log to the directory from where it is launched, named in the format `gfsh-&lt;unique&gt;-&lt;generation&gt;.log` (for example, `gfsh-0-0.log`); shells started concurrently in the same directory receive distinct file names. Because these files are written on the administrative host rather than on the GemFire nodes, collect them from that host if you need to retain them.

### Customizing Log4j 2 for Centralized Logging
The `log-*` settings in `gemfire.properties` are a deliberately narrow interface. They configure GemFire's built-in `GeodeLogWriter` appender and control only the log level, file name, per-file size limit, and total disk-space limit, writing plain-text rolling files to each member's local disk. That model cannot forward logs off the host, emit structured output, set per-package log levels, or log asynchronously. Because GemFire is built directly on Apache Log4j 2, supplying your own `log4j2.xml` unlocks the full Log4j 2 feature set, which is what centralized, enterprise-grade logging requires. This path is intended for advanced users who need that level of control, or who must integrate GemFire logging with the logging APIs of third-party libraries.

A custom `log4j2.xml` enables the capabilities the property-based model does not:

* Off-host forwarding, using a Syslog appender (to rsyslog or VMware Aria Operations for Logs), a Socket appender, or a vendor or community appender for Splunk, Apache Kafka, Elasticsearch, or Loki. This provides durability beyond a single node or disk, together with central retention, aggregation, and search across all members and sites.  
* Structured output, using a JSON layout so logs parse directly into platforms such as ELK, Splunk, or Loki for dashboards and alerting.  
* Per-package and per-class log levels, so a single component can be raised to DEBUG while the rest of the member stays at INFO.  
* Asynchronous loggers and appenders, which reduce logging overhead and latency under GemFire's high thread concurrency.  
* Correlation across members (with NTP-synchronized clocks) and with your application and third-party library logs, using the bridge, binding, and adapter JARs described earlier.

An example configuration file ships with the product distribution at `$GEMFIRE/config/log4j2.xml`. To supply your own file (`.xml`, `.json`, or `.yaml`), start the JVM or GemFire member with the `-Dlog4j.configurationFile=&lt;path&gt;` flag. When `log4j.configurationFile` is set, GemFire does not use the `log4j2.xml` bundled in `gemfire-log4j-&lt;version&gt;.jar`.

Adopting a custom configuration also means taking on its operational responsibilities. In particular, the `alter runtime --log-level` and `change loglevel` runtime controls work as-is with the default configuration, but when a custom Log4j 2 configuration is in use, `change loglevel` takes effect only if the member was started with the `geode.LOG_LEVEL_UPDATE_OCCURS=ALWAYS` system property.  
When customizing `log4j2.xml`, observe these product-specific caveats from the GemFire 10.3 [product documentation](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-gemfire/10-1/gf/managing-logging-configuring_log4j2.html):

* Do not set `monitorInterval=` in the file. It makes Log4j 2 re-read and reload the configuration at runtime, which can have a significant performance impact.  
* Keep `status="FATAL"` on the Configuration element. Log4j 2's StatusLogger otherwise writes ERROR-level warnings to standard out whenever GemFire stops its AlertAppender or LogWriterAppender. This happens routinely, because GemFire runs many concurrent threads that may still be logging as those appenders stop.  
* Keep `shutdownHook="disable"` on the Configuration element. GemFire installs its own shutdown hook, which disconnects the DistributedSystem and closes the Cache. If the Log4j 2 shutdown hook stops logging before GemFire finishes shutting down, Log4j 2 tries to restart, fails to register a second shutdown hook, and logs a FATAL message.  
* Minimize filters. Using filters can reduce performance, because some GemFire logging optimizations are deactivated when filters are present. The one exception is the `GEODE_VERBOSE` marker filter described below.  
* Retain the GemFire appenders you rely on. Removing the `GeodeAlert` (ALERT) reference disables alert federation to JMX and the Management Console, and removing `GeodeLogWriter` (LOGWRITER) stops writing the standard member log files. Add new appenders (such as Syslog) alongside them, rather than replacing them.

**Declaring GemFire's custom appenders.** When writing your own `log4j2.xml`, define the GemFire log pattern and declare the custom appenders as shown below. Note that `GeodeAlert` does not take a PatternLayout.

```xml
<Properties>
  <Property name="gemfire-pattern">[%level{lowerCase=true} %date{yyyy/MM/dd HH:mm:ss.SSS z} <%thread> tid=%hexTid] %message%n%throwable%n</Property>
</Properties>

<Appenders>
  <GeodeConsole name="STDOUT" target="SYSTEM_OUT">
    <PatternLayout pattern="${gemfire-pattern}"/>
  </GeodeConsole>
  <GeodeLogWriter name="LOGWRITER">
    <PatternLayout pattern="${gemfire-pattern}"/>
  </GeodeLogWriter>
  <GeodeAlert name="ALERT"/>
</Appenders>
```

Use the default `log4j2.xml` in your GemFire distribution's `config` directory as the reference for any custom configuration. This forwarding path is the GemFire-side basis for production centralized logging: the Management Console's Logs tab suits quick, live inspection, while a custom `log4j2.xml` is what makes member logs durable, aggregated, and searchable off-host.

### Integrating with Centralized Logging Systems
To forward logs from all Tanzu GemFire members (locators and servers) to a centralized log server (e.g., rsyslog), perform the following steps:

* Configure the Rsyslog Server  
  Set up rsyslog as a centralized log server and enable TCP input to receive logs.  
  Example /etc/rsyslog.conf:

```shell
module(load="imtcp")
input(type="imtcp" port="5514")
```

* Add a Dedicated Rsyslog Rule  
  Create a rule to write GemFire logs to a specific file with proper permissions:

```shell
if ($fromhost-ip == 'Locator-IP' or $fromhost-ip == 'Server-IP') then {
    action(type="omfile" file="/var/log/gemfire-remote.log")
    stop
}
```

* Update GemFire's log4j2.xml  
  Modify each member's Log4j 2 configuration file (log4j2.xml) to include a Syslog Appender that forwards logs to the centralized server.  
  Sample configuration:

```xml
<Appenders>
  <!-- Console Appender -->
  <GeodeConsole name="STDOUT" target="SYSTEM_OUT">
    <PatternLayout pattern="${gemfire-pattern}"/>
  </GeodeConsole>
  <!-- GemFire Default Log File -->
  <GeodeLogWriter name="LOGWRITER">
    <PatternLayout pattern="${gemfire-pattern}"/>
  </GeodeLogWriter>
  <!-- Security Log (if enabled) -->
  <GeodeLogWriter name="SECURITYLOGWRITER" security="true">
    <PatternLayout pattern="${gemfire-pattern}"/>
  </GeodeLogWriter>
  <!-- Alert Notifications -->
  <GeodeAlert name="ALERT"/>
  <!-- Syslog Appender (TCP, RFC5424) -->
  <Syslog name="SYSLOG"
          host="SYSLOG_IP"
          port="5514"
          protocol="TCP"
          format="RFC5424"
          newLine="true"
          appName="GemFire"
          enterpriseNumber="18060">
    <PatternLayout pattern="${gemfire-pattern}"/>
  </Syslog>
</Appenders>
```

* Then reference the new Syslog appender in your root logger:

```xml
<Loggers>
  <Root level="info">
    <AppenderRef ref="SYSLOG"/>
    <AppenderRef ref="LOGWRITER"/>
  </Root>
</Loggers>
```

* Restart GemFire Members  
  Restart all locators and servers to apply the new configuration.

Best Practices

* Always direct logs to files rather than standard output for easier collection and analysis.  
* Ensure each member has a unique log file for clarity.  
* Regularly rotate and archive logs to prevent disk exhaustion.  
* Use synchronized clocks (NTP) across all nodes for accurate log correlation.  
* Periodically inspect logs for unexpected warnings or severe events.

