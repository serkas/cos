job "logging" {
  datacenters = ["public-services"]
  type = "service"

  group "logging_group" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "elasticsearch" {
      driver = "docker"
      config {
        image = "<aws_account_id>.dkr.ecr.us-east-1.amazonaws.com/service/elasticsearch:2018-03-23_14-24-43c9c450b_dirty"

        port_map = {
          http = 9200
          node = 9300
        }

        ulimit {
          nofile = "65536:65536"
        }

        volumes = [
          "local/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml"
        ]
      }

      resources {
        cpu    =  800 # MHz
        memory = 1100 # MB
        network {
          mbits = 10
          port "http" {}
          port "node" {}
        }
      }

      service {
        name = "elasticsearch"
        tags = ["urlprefix-/elasticsearch"] # fabio
        port = "http"
        check {
          name     = "Elasticsearch Alive State"
          port     = "http"
          type     = "http"
          method   = "GET"
          path     = "/_cluster/health"
          interval = "10s"
          timeout  = "2s"
        }
      }

      env {
        # FIXME: Using values near the memory limit did not work.
        #        OOS killed the container because the memory limit was reached.
        #        Might be a bug in Java.
        ES_JAVA_OPTS = "-Xmx256m -Xms256m"
      }

      template {
        data = <<EOH
cluster.name: "es-logging-cluster"
network.host: 0.0.0.0

discovery.zen.minimum_master_nodes: 1

action.auto_create_index: fluentd*

EOH
        destination = "local/elasticsearch.yml"
        change_mode = "noop"
      }
    }

    task "kibana" {
      driver = "docker"
      config {
        image = "<aws_account_id>.dkr.ecr.us-east-1.amazonaws.com/service/kibana:2018-03-23_14-20-25c9c450b_dirty"
        port_map = {
          http = 5601
        }

        volumes = [
          "local/kibana.yml:/usr/share/kibana/config/kibana.yml"
        ]
      }

      resources {
        cpu    =  800 # MHz
        memory = 1100 # MB
        network {
          mbits = 10
          port "http" {}
        }
      }

      service {
        name = "kibana"
        tags = ["urlprefix-/kibana"] # Fabio
        port = "http"
        check {
          name = "Kibana Alive State"
          port = "http"
          type = "http"
          method = "GET"
          path = "/api/status"
          interval = "10s"
          timeout = "2s"
        }
      }

      template {
        data = <<EOH
server.name: logging-cluster-ui
server.host: "0"
# FIXME: HACK - this initial configuration might to be stable. Service Discovery should be used!
elasticsearch.url: "http://{{ env "NOMAD_IP_elasticsearch_http" }}:{{ env "NOMAD_PORT_elasticsearch_http" }}/"

EOH
        destination = "local/kibana.yml"
        change_mode = "noop"
      }
    }
  }
}
