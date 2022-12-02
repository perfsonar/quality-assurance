// docker bake configuration

// Variables used in this file, docker-compose and Dockerfile
// See following references:
// https://docs.docker.com/engine/reference/commandline/buildx_bake/#hcl-variables-and-functions
// https://github.com/docker/buildx/blob/master/bake/hclparser/stdlib.go
// https://github.com/zclconf/go-cty/tree/main/cty/function/stdlib

variable "REPO" {
    default = "perfsonar-repo-staging"
}
variable "OSimage" {
    default = "centos:7"
}
variable "useproxy" {
    default = "without"
}
variable "proxy" {
    default = ""
}

// Defaults
group "default" {
    targets = [
        "single_test_centos_7",
        "single_test_almalinux_8"
    ]
}

// All the build targets
target "root_target" {
    target = "install-image"
    args = {
        OSimage = OSimage
        REPO = REPO
        useproxy = useproxy
        proxy = proxy
    }
    output = ["type=cacheonly"]
}
target "single_test" {
    inherits = ["root_target"]
    output = ["type=docker"]
    tags = ["${REPO}/${OSimage}"]
}
target "single_test_centos_7" {
    inherits = ["single_test"]
    args = {
        OSimage = "centos:7"
    }
    tags = ["${REPO}/centos:7"]
}
target "single_test_almalinux_8" {
    inherits = ["single_test"]
    args = {
        OSimage = "almalinux:8"
    }
    tags = ["${REPO}/almalinux:8"]
}
target "full_arch_test" {
    inherits = ["root_target"]
    platforms = ["linux/amd64"]
    output = ["type=registry"]
    tags = ["docker.io/ntw0n/${REPO}/${OSimage}"]
}


