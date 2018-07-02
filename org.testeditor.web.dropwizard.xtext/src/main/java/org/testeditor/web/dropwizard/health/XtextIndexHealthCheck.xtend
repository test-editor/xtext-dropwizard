package org.testeditor.web.dropwizard.health

import com.codahale.metrics.health.HealthCheck
import javax.inject.Inject
import org.testeditor.web.xtext.index.ChunkedResourceDescriptionsProvider
import com.codahale.metrics.health.HealthCheck.Result

class XtextIndexHealthCheck extends HealthCheck {
	@Inject ChunkedResourceDescriptionsProvider resourceDescriptionsProvider
	
	override protected check() throws Exception {
		return if (resourceDescriptionsProvider.getResourceDescriptions(resourceDescriptionsProvider.indexResourceSet).empty) {
			Result.unhealthy('The Xtext index appears to be empty')
		} else {
			Result.healthy
		}
	}
	
}
