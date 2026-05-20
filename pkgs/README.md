# pkgs/ — Vendored MycoTools tarball

This folder holds the **currently-pinned `MycoTools` tarball** that
`renv` installs from. Posit Connect Cloud deploys from this repo's git
checkout, so the tarball must live here for the package to be
installable during deploy.

Keep exactly **one** tarball in this folder at a time. The full version
history lives in the umbrella repo at `mycotools-project/pkgs/`.

## Bumping to a new MycoTools version

```
# In an R session, from the ShinyMycoTools root:
Remove-Item pkgs/MycoTools_*.tar.gz      # drop the old one
Copy-Item ../pkgs/MycoTools_<new>.tar.gz pkgs/
renv::install("pkgs/MycoTools_<new>.tar.gz")
renv::snapshot()
rsconnect::writeManifest()
```

Then commit `pkgs/`, `renv.lock`, and `manifest.json` together.
