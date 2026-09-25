# color-block-gitops

The GitOps repo behind the live demo in *Commit to Production* (AWS Student Community Day).

Argo CD watches `k8s/` on `main`. Change the `COLOR` env var in [`k8s/deployment.yaml`](k8s/deployment.yaml),
push, and Argo CD rolls the new color out to every pod on Amazon EKS. Nothing else deploys to the cluster.

```
k8s/          what runs in the cluster (Deployment, Service, nginx template)
argocd/       the Argo CD Application (auto-sync, prune, self-heal)
infra/        eksctl config plus up/down scripts
.github/      manifest validation on every push
```

## Try it yourself

```bash
./infra/up.sh      # EKS + Argo CD + this app (about 20 min)
# edit COLOR in k8s/deployment.yaml, commit, push, then watch:
kubectl -n demo get pods -w
kubectl -n demo port-forward svc/color-block 8080:80   # http://localhost:8080
./infra/down.sh    # delete everything when you're done
```

Want to see self-heal? Change the cluster by hand and watch Argo CD put it back:

```bash
kubectl -n demo scale deploy/color-block --replicas=2
```

Rollback is `git revert`.
