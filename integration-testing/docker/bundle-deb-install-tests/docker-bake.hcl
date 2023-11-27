// docker bake configuration

// Variables used in this file, docker-compose and Dockerfile
// See following references:
// https://docs.docker.com/engine/reference/commandline/buildx_bake/#hcl-variables-and-functions
// https://github.com/docker/buildx/blob/master/bake/hclparser/stdlib.go
// https://github.com/zclconf/go-cty/tree/main/cty/function/stdlib

variable "REPO" {
    default = "perfsonar-patch-snapshot"
}
variable "OSimage" {
    default = "debian:buster"
}
variable "OSfamily" {
    default = regex_replace("${OSimage}", ":.*", "")
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
        "single_test_debian_buster",
        "single_test_debian_bullseye",
        "single_test_debian_bookworm",
        "single_test_ubuntu_focal",
        "single_test_ubuntu_jammy"
    ]
}
group "arches" {
    targets = [
        "full_arch_test"
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
target "single_test_debian_buster" {
    inherits = ["single_test"]
    args = {
        OSimage = "debian:buster"
    }
    tags = ["${REPO}/debian:buster"]
}
target "single_test_debian_bullseye" {
    inherits = ["single_test"]
    args = {
        OSimage = "debian:bullseye"
    }
    tags = ["${REPO}/debian:bullseye"]
}
target "single_test_debian_bookworm" {
    inherits = ["single_test"]
    args = {
        OSimage = "debian:bookworm"
    }
    tags = ["${REPO}/debian:bookworm"]
}
target "single_test_ubuntu_focal" {
    inherits = ["single_test"]
    args = {
        OSimage = "ubuntu:focal"
    }
    tags = ["${REPO}/ubuntu:focal"]
}
target "single_test_ubuntu_jammy" {
    inherits = ["single_test"]
    args = {
        OSimage = "ubuntu:jammy"
    }
    tags = ["${REPO}/ubuntu:jammy"]
}
target "full_arch_test" {
    inherits = ["root_target"]
//    platforms = ["linux/amd64", "linux/arm64", "linux/arm/v7", "linux/ppc64le"]
    platforms = ["linux/amd64", "linux/arm64"]
    output = ["type=registry"]
    tags = ["docker.io/ntw0n/${REPO}/${OSimage}"]
}


