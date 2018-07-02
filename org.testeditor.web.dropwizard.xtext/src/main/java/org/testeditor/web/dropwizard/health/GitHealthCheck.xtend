package org.testeditor.web.dropwizard.health

import com.codahale.metrics.health.HealthCheck
import javax.inject.Inject
import com.codahale.metrics.health.HealthCheck.Result
import org.testeditor.web.xtext.index.persistence.GitService

class GitHealthCheck extends HealthCheck {
	@Inject GitService git
	
	override protected check() throws Exception {
		val conflicts = git.conflicts
		
		return if (conflicts.nullOrEmpty) {
			Result.healthy
		} else {
			Result.unhealthy('Working copy contains conflicts.', conflicts)
		}
	}
}
