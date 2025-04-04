# Changes in graphite client

There are several changes in graphite-remote-adapter for escaping tags in metrics:

In file `client/graphite/paths/write.go`

```go

                k := string(l)
-               v := graphite_tmpl.Escape(string(m[l]))
+               v := string(m[l])

                if format == FormatCarbonOpenMetrics {
                        // https://github.com/RichiH/OpenMetrics/blob/master/metric_exposition_format.md
                        if !first {
                                lbuffer.WriteString(",")
                        }
-                       lbuffer.WriteString(fmt.Sprintf("%s=\"%s\"", k, v))
+                       lbuffer.WriteString(fmt.Sprintf("%s=\"%s\"", k, graphite_tmpl.Escape(v)))
                } else if format == FormatCarbonTags {
                        // See http://graphite.readthedocs.io/en/latest/tags.html
-                       lbuffer.WriteString(fmt.Sprintf(";%s=%s", k, v))
+                       lbuffer.WriteString(fmt.Sprintf(";%s=%s", k, graphite_tmpl.EscapeTagged(v)))
                } else {
                        // For each label, in order, add ".<label>.<value>".
                        // Since we use '.' instead of '=' to separate label and values
                        // it means that we can't have an '.' in the metric name. Fortunately
                        // this is prohibited in prometheus metrics.
-                       lbuffer.WriteString(fmt.Sprintf(".%s.%s", k, v))
+                       lbuffer.WriteString(fmt.Sprintf(".%s.%s", k, graphite_tmpl.Escape(v)))
                }
                first = false

```

In file `client/graphite/paths/write_test.go` changed test:

```go
func TestDefaultPathsFromMetric(t *testing.T) {
        require.Equal(t, expected, actual[0])
        require.Empty(t, err)

+       // This expected result is different from other expect expressions in this test because for work with
+       // Graphite + ClickHouse + Prometheus datasource was added new EscapeTagged into
+       // ./client/graphite/template/escape.go. This new method change escape behavior for format "Carbot Tags"
        expected = "prefix." +
                "test:metric" +
-               ";many_chars=abc!ABC:012-3!45%C3%B667~89%2E%2F\\(\\)\\{\\}\\,%3D%2E\\\"\\\\" +
+               ";many_chars=abc!ABC:012-3!45%C3%B667_89./(){},_.\"\\" +
                ";owner=team-X" +
                ";testlabel=test:value"
```

In file `client/graphite/template/escape.go` added function `EscapeTagged`:

```go
// EscapeTagged unlike Escape() method replace symbols:
//
// - semicolon (;)
// - tilde (~)
// - space ( )
// - equality (=)
//
// to underscore (_).
//
// Such encoding allow push metrics with tags (into Carbon Tag format) into bundle Graphite + ClickHouse
// and use it further into Prometheus (just a clever wrapper under Graphite) grafana datasource which load
// data from Graphite directly.
//
// Other symbols escaped by logic described into Escape() method. Please refer to it documentation for details.
//
// Examples:
//
// "foo bar 42" -> "foo_bar_42"
//
// "foo_bar~42;bar=42" -> "foo_bar_bar_42"
//
// "http://example.org:8080" -> "http:%2F%2Fexample%2Eorg:8080"
//
// "Björn's email: bjoern@soundcloud.com" -> "Bj%C3%B6rn's_email:_bjoern%40soundcloud.com"
//
// "日" -> "%E6%97%A5"
func EscapeTagged(tv string) string {
    length := len(tv)
    result := bytes.NewBuffer(make([]byte, 0, length))
    for i := 0; i < length; i++ {
        b := tv[i]
        switch {
        case b == ';' || b == '~' || b == ' ' || b == '=':
            result.WriteString("_")
        // These are all fine.
        case strings.IndexByte(printables, b) != -1:
            result.WriteByte(b)
        // Defaults to percent-encoding.
        default:
            fmt.Fprintf(result, "%%%X", b)
        }
    }
    return result.String()
}
```

And in `main.go` for extending logs:

```go
 func main() {
        cliCfg := config.ParseCommandLine()

-       logger := promlog.New(&promlog.Config{Level: &cliCfg.LogLevel})
+       logger := promlog.New(&promlog.Config{Level: &cliCfg.LogLevel, Format: &promlog.AllowedFormat{}})
        level.Info(logger).Log("msg", "Starting graphite-remote-adapter", "version", version.Info())
        level.Info(logger).Log("build_context", version.BuildContext())
```
