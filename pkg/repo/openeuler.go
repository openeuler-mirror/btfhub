package repo

import (
	"context"
	"errors"
	"fmt"
	"log"
	"regexp"
	"sort"
	"strings"

	"gitee.com/openeuler/btfhub/pkg/job"
	"gitee.com/openeuler/btfhub/pkg/kernel"
	"gitee.com/openeuler/btfhub/pkg/pkg"
	"gitee.com/openeuler/btfhub/pkg/utils"
)

const (
	debugInfo = "debuginfo"
	update    = "update"
)

type OpenEulerRepo struct {
	archs        map[string]string
	releases     map[string][]string
	repoTemplate string
}

func NewOpenEulerRepo() Repository {
	return &OpenEulerRepo{
		// TODO: Add more architectures (if necessary)
		archs: map[string]string{
			"x86_64": "x86_64",
			"arm64":  "aarch64",
		},
		releases: map[string][]string{
			"20.03": {
				"20.03-LTS-SP1",
				"20.03-LTS-SP3",
			},
			"22.03": {
				"22.03-LTS",
				"22.03-LTS-SP1",
				"22.03-LTS-SP2",
			},
			"23.03": {
				// FIXME: vmlinux does not exist in kernel-debuginfo
				"23.03",
			},
		},
		repoTemplate: "https://repo.openeuler.org/openEuler-%s/%s/%s/Packages/",
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
	altReleases := d.releases[release]

	debugInfolinks, err := d.getRepoDebugInfoLinks(altReleases, altArch)
	if err != nil {
		return err
	}

	updateLinks, err := d.getRepoUpdateLinks(altReleases, altArch)
	if err != nil {
		return err
	}

	links := append(debugInfolinks, updateLinks...)

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

func (d *OpenEulerRepo) getRepoDebugInfoLinks(altReleases []string, altArch string) ([]string, error) {
	var debugInfolinks []string

	for _, altRelease := range altReleases {
		repoURL := fmt.Sprintf(d.repoTemplate, altRelease, debugInfo, altArch)
		repoLinks, err := utils.GetLinks(repoURL)
		if err != nil {
			return nil, fmt.Errorf("ERROR: list packages, %s", err)
		}
		debugInfolinks = append(debugInfolinks, repoLinks...)
	}

	return debugInfolinks, nil
}

func (d *OpenEulerRepo) getRepoUpdateLinks(altReleases []string, altArch string) ([]string, error) {
	var updateLinks []string

	for _, altRelease := range altReleases {
		repoURL := fmt.Sprintf(d.repoTemplate, altRelease, update, altArch)
		repoLinks, err := utils.GetLinks(repoURL)
		if err != nil {
			return nil, fmt.Errorf("ERROR: updatelist packages, %s", err)
		}
		updateLinks = append(updateLinks, repoLinks...)
	}

	return updateLinks, nil
}
