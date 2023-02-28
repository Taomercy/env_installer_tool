After apply kubernetes-dashbaord.yaml
Need create clusterrolebing
cmd: kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:kubernetes-dashboard

Get secret:
cmd: 
pod=$(kubectl get secret -n kubernetes-dashboard | awk '{print $1}' | grep "kubernetes-dashboard-token")
kubectl describe secret $pod  -n kubernetes-dashboard
or:
kubectl get secret $pod  -n kubernetes-dashboard -o jsonpath={.data.token}|base64 -d

