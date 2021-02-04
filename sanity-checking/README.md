# sanity-checking

## TODO:
 - [ ] Add high-level Overview
 - [ ] Add possible future directions
 - [ ] Update/generalize paths


Building:
```
docker build -t sanity .
```

Running:
```
docker run --privileged --name sanity --network host --rm sanity
```

If running it to test development, you could do something like this. Use `-v` to override the `sanity.pl` file within the container with one on your local filesystem.

```
docker run --privileged --name sanity --network host -v /path/to/dev/sanity.pl:/app/sanity.pl  --rm sanity
```

## SINGLE

Building:
```
docker build -t single-sanity -f Dockerfile-single .
```

Running:
```
docker run --privileged  --name single-sanity --network host --rm single-sanity
```

If running it to test development, you could do something like this. Use `-v` to override the `single-sanity.pl` file within the container with one on your local filesystem.

```
docker run --privileged  --name single-sanity --network host -v /path/to/dev/single-sanity.pl:/app/single-sanity.pl  --rm single-sanity
```
