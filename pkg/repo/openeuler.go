package repo

import (
	"context"
	"errors"
	"fmt"
	"log"
	"regexp"
	"sort"
	"strings"

	"github.com/aquasecurity/btfhub/pkg/job"
	"github.com/aquasecurity/btfhub/pkg/kernel"
	"github.com/aquasecurity/btfhub/pkg/pkg"
	"github.com/aquasecurity/btfhub/pkg/utils"
)

type OpenEulerRepo struct {
	archs map[string]string
	repos map[string]string
}

func NewOpenEulerRepo() Repository {
	return &OpenEulerRepo{
		// TODO: Add more architectures (if necessary)
		archs: map[string]string{
			"x86_64": "x86_64",
			"arm64":  "aarch64",
		},
		repos: map[string]string{
			"20.03-LTS-SP3": "https://repo.openeuler.org/openEuler-20.03-LTS-SP3/debuginfo/%s/Packages/",
			"22.03-LTS":     "https://repo.openeuler.org/openEuler-22.03-LTS/debuginfo/%s/Packages/",
			"22.03-LTS-SP1": "https://repo.openeuler.org/openEuler-22.03-LTS-SP1/debuginfo/%s/Packages/",
			"22.03-LTS-SP2": "https://repo.openeuler.org/openEuler-22.03-LTS-SP2/debuginfo/%s/Packages/",
			"23.03":         "https://repo.openeuler.org/openEuler-23.03/debuginfo/%s/Packages/", // FIXME: vmlinux does not exist in kernel-debuginfo
		},
	}
}

func (d *OpenEulerRepo) GetKernelPackages(
	ctx context.Context,
	workDir string,
	release string,
	arch string,
	jobChan chan<- job.Job,
) error {
	var pkgs []pkg.Package

	altArch := d.archs[arch]
	repoURL := fmt.Sprintf(d.repos[release], altArch)

	links, err := utils.GetLinks(repoURL)
	if err != nil {
		return fmt.Errorf("ERROR: list packages, %s", err)
	}

	kre := regexp.MustCompile(fmt.Sprintf(`kernel-debuginfo-([-1-9].*\.%s)\.rpm`, altArch))

	for _, l := range links {
		if match := kre.FindStringSubmatch(l); match != nil {
			name := strings.TrimSuffix(match[0], ".rpm")
			p := &pkg.OpenEulerPackage{
				Name:          name,
				Architecture:  altArch,
				KernelVersion: kernel.NewKernelVersion(match[1]),
				NameOfFile:    match[1],
				URL:           l,
			}
			pkgs = append(pkgs, p)
		}
	}

	sort.Sort(pkg.ByVersion(pkgs))

	for i, pkg := range pkgs {
		log.Printf("DEBUG: start pkg %s (%d/%d)", pkg, i+1, len(pkgs))

		if err := processPackage(ctx, pkg, workDir, jobChan); err != nil {
			if errors.Is(err, utils.ErrHasBTF) {
				log.Printf("INFO: kernel %s has BTF already; skipping later kernels\n", pkg)
				return nil
			}
			if errors.Is(err, context.Canceled) {
				return nil
			}

			log.Printf("ERROR: %s: %s\n", pkg, err)
			continue
		}

		log.Printf("DEBUG: end pkg %s (%d/%d)\n", pkg, i+1, len(pkgs))
	}

	return nil
}
