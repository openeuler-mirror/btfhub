package repo

import (
	"context"
	"errors"
	"fmt"
	"log"
	"sort"

	"gitee.com/openeuler/btfhub/pkg/job"
	"gitee.com/openeuler/btfhub/pkg/kernel"
	"gitee.com/openeuler/btfhub/pkg/pkg"
	"gitee.com/openeuler/btfhub/pkg/utils"
)

type AmazonRepo struct {
	archs map[string]string
}

func NewAmazonRepo() Repository {
	return &AmazonRepo{
		archs: map[string]string{
			"x86_64": "x86_64",
			"arm64":  "aarch64",
		},
	}
}

func (d *AmazonRepo) GetKernelPackages(ctx context.Context, dir string, release string, arch string, jobchan chan<- job.Job) error {
	searchOut, err := yumSearch(ctx, "kernel-debuginfo")
	if err != nil {
		return err
	}
	pkgs, err := parseYumPackages(searchOut, kernel.NewKernelVersion(""))
	if err != nil {
		return fmt.Errorf("parse package listing: %s", err)
	}
	sort.Sort(pkg.ByVersion(pkgs))

	for _, pkg := range pkgs {
		err := processPackage(ctx, pkg, dir, jobchan)
		if err != nil {
			if errors.Is(err, utils.ErrHasBTF) {
				log.Printf("INFO: kernel %s has BTF already, skipping later kernels\n", pkg)
				return nil
			}
			return err
		}
	}

	return nil
}
