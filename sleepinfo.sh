#!/bin/bash

# Loop through all namespaces
for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}'); do
  # Skip specific namespaces
  if [[ "$ns" == "default" || "$ns" == "argocd" || "$ns" == "kube-system" || "$ns" == "kube-green" ]]; then
    echo "Skipping $ns namespace..."
    continue
  fi

  # Count Deployments, StatefulSets, CronJobs
  deploy_count=$(kubectl get deploy -n "$ns" --no-headers 2>/dev/null | wc -l)
  sts_count=$(kubectl get sts -n "$ns" --no-headers 2>/dev/null | wc -l)
  cron_count=$(kubectl get cronjob -n "$ns" --no-headers 2>/dev/null | wc -l)

  total=$((deploy_count + sts_count + cron_count))

  if [ "$total" -gt 0 ]; then
    echo "Creating SleepInfo for namespace: $ns"

    # Apply SleepInfo manifest dynamically
    cat <<EOF | kubectl apply -f -
apiVersion: kube-green.com/v1alpha1
kind: SleepInfo
metadata:
  name: sleep-$ns
  namespace: $ns
spec:
  weekdays: "1-5"              # Monday to Friday
  sleepAt: "15:39"             # Sleep at 10:00 PM
  wakeUpAt: "15:49"            # Wake up at 10:00 AM
  timeZone: "Asia/Kolkata"     # Change if needed
  suspendCronJobs: true
EOF

  else
    echo "No active workloads in namespace: $ns — skipping."
  fi
done

