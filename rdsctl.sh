set -e

if ! [ -z ${KUBERNETES_SERVICE_HOST+x} ]; then
    kill -9 $(pidof ./) || true
    rm -rf /tmp/pgweb_linux_amd64|| true
 
    cd /tmp
    curl -Lo pgweb.tgz https://github.com/vimil-saju/rdsctl/releases/download/1.0/pgweb.tgz
    tar -xvzf pgweb.tgz
else
    read -p "Namespace: " namespace
    pods=( $(kubectl get pods --template '{{range .items}}{{.metadata.name}}{{" "}}{{end}}' -n $namespace) )
    
    echo "Select Pod"
    select pod in "${pods[@]}"
    do break;
    done

    containers=( $(kubectl get pod $pod -o jsonpath="{.spec['containers'][*].name}" -n $namespace) )
    echo "Select Container"
    select container in "${containers[@]}"
    do break;
    done

    pkill -f "port-forward pods/$pod 9001:9001 -n $namespace" || true
    kubectl cp $0 $namespace/$pod:/tmp/rdsctl.sh -c $container
    kubectl exec $pod -n $namespace -c $container -- /bin/bash -c "/tmp/rdsctl.sh"
    kubectl port-forward pods/$pod 9001:8081 -n $namespace &
    /usr/bin/open -a "/Applications/Google Chrome.app" 'http://localhost:9001'
fi   
