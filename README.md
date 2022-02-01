# subimagemoco
Motion Correction of multi-shot MR data using sub images

Additional documentation on shared Overleaf:
https://www.overleaf.com/read/zdphnxpztspy 

Overleaf file on February 1, 2022 refered to code at Git Tag `1Feb2022`. The version on 20 January 2022 contained a bug. Fixing this has improved the results.

The stable git branch is `master`, not `main`. The principle function is `subimage.m` in the `source` folder.

The code is being developed using the MATLAB Project functionality, hence the additional files. 

Currently also requires `k2i` and `i2k` that are not in this repo. `d_apply` was copied in from a private repo and renamed - this should be tidied up at some point. `k2i` is just 
`cimdat = fftshift(ifftn(ifftshift(ckdat))) ;` and `i2k` is `ckdat = fftshift(fftn(ifftshift(cimdat))) ;`

