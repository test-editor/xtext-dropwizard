package org.testeditor.web.dropwizard.health

import com.codahale.metrics.health.HealthCheck
import javax.inject.Inject
import org.slf4j.LoggerFactory
import org.testeditor.web.xtext.index.ChunkedResourceDescriptionsProvider

class XtextIndexHealthCheck extends HealthCheck {

	static val logger = LoggerFactory.getLogger(XtextIndexHealthCheck)

	@Inject ChunkedResourceDescriptionsProvider resourceDescriptionsProvider

	override protected check() throws Exception {
		logger.info('health check request received')
		return if (resourceDescriptionsProvider.getResourceDescriptions(resourceDescriptionsProvider.indexResourceSet).empty) {
			logger.info('not at all well (the Xtext index appears to be empty)')
			Result.unhealthy('The Xtext index appears to be empty')
		} else {
			logger.info('clean bill of health (index has been filled)')
			Result.healthy
		}
	}

}
