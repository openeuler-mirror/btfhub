package pkg

import (
	"context"
	"fmt"
	"os"
	"path/filepath"

	"gitee.com/openeuler/btfhub/pkg/kernel"
	"gitee.com/openeuler/btfhub/pkg/utils"
)

type FedoraPackage struct {
	Name          string
	Architecture  string
	KernelVersion kernel.Version
	NameOfFile    string
	URL           string
}

func (pkg *FedoraPackage) Filename() string {
	return pkg.NameOfFile
}

func (pkg *FedoraPackage) Version() kernel.Version {
	return pkg.KernelVersion
}

func (pkg *FedoraPackage) SkipExistingBTF() bool {
	return true
}

func (pkg *FedoraPackage) String() string {
	return pkg.Name
}

func (pkg *FedoraPackage) ExtractKernel(ctx context.Context, pkgpath string, vmlinuxPath string) error {
	return utils.ExtractVmlinuxFromRPM(ctx, pkgpath, vmlinuxPath)
}

func (pkg *FedoraPackage) Download(ctx context.Context, workDir string) (string, error) {

	localFile := fmt.Sprintf("%s.rpm", pkg.NameOfFile)
	rpmPath := filepath.Join(workDir, localFile)

	if utils.Exists(rpmPath) {
		return rpmPath, nil
	}

	err := utils.DownloadFile(ctx, pkg.URL, rpmPath)
	if err != nil {
		os.Remove(rpmPath)
		return "", fmt.Errorf("downloading rpm package: %s", err)
	}

	return rpmPath, nil
}
