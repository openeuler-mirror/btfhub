package pkg

import (
	"context"
	"fmt"
	"os"
	"path/filepath"

	"gitee.com/openeuler/btfhub/pkg/kernel"
	"gitee.com/openeuler/btfhub/pkg/utils"
)

type OpenEulerPackage struct {
	Name          string
	Architecture  string
	KernelVersion kernel.Version
	NameOfFile    string
	URL           string
}

func (pkg *OpenEulerPackage) String() string {
	return pkg.Name
}

func (pkg *OpenEulerPackage) Filename() string {
	return pkg.NameOfFile
}

func (pkg *OpenEulerPackage) Version() kernel.Version {
	return pkg.KernelVersion
}

func (pkg *OpenEulerPackage) SkipExistingBTF() bool {
	// It is supposed to build BTF for every kernel present in openEuler YUM repository,
	// regardless of whether BTF information already exists in the kernel
	return false
}

func (pkg *OpenEulerPackage) Download(ctx context.Context, dir string) (string, error) {
	localFile := fmt.Sprintf("%s.rpm", pkg.NameOfFile)
	rpmpath := filepath.Join(dir, localFile)

	if utils.Exists(rpmpath) {
		return rpmpath, nil
	}

	if err := utils.DownloadFile(ctx, pkg.URL, rpmpath); err != nil {
		os.Remove(rpmpath)
		return "", fmt.Errorf("downloading rpm package: %s", err)
	}

	return rpmpath, nil
}

func (pkg *OpenEulerPackage) ExtractKernel(ctx context.Context, pkgpath string, vmlinuxPath string) error {
	return utils.ExtractVmlinuxFromRPM(ctx, pkgpath, vmlinuxPath)
}
