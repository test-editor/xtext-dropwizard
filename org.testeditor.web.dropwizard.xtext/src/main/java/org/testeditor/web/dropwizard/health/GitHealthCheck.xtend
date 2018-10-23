package org.testeditor.web.dropwizard.health

import com.codahale.metrics.health.HealthCheck
import javax.inject.Inject
import org.slf4j.LoggerFactory
import org.testeditor.web.xtext.index.persistence.GitService

class GitHealthCheck extends HealthCheck {

	static val logger = LoggerFactory.getLogger(GitHealthCheck)

	@Inject GitService git

	override protected check() throws Exception {
		logger.info('health check request received')
		val conflicts = git.conflicts

		return if (conflicts.nullOrEmpty) {
			logger.info('clean bill of health (no conflicts detected)')
			Result.healthy
		} else {
			logger.warn('not at all well (working copy contains conflicts)')
			Result.unhealthy('Working copy contains conflicts.', conflicts)
		}
	}

}
