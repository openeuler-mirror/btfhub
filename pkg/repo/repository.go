package repo

import (
	"context"

	"gitee.com/openeuler/btfhub/pkg/job"
)

type Repository interface {
	GetKernelPackages(
		ctx context.Context,
		workDir string,
		release string,
		arch string,
		jobChan chan<- job.Job,
	) error
}
