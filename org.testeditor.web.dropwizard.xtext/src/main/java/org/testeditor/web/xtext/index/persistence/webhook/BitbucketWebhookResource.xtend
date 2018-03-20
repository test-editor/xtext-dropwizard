package org.testeditor.web.xtext.index.persistence.webhook

import javax.inject.Inject
import javax.ws.rs.POST
import javax.ws.rs.Path
import javax.ws.rs.core.Response
import org.testeditor.web.dropwizard.auth.ApiTokenAuth
import org.testeditor.web.xtext.index.BuildCycleManager

import static javax.ws.rs.core.Response.Status.*
import static javax.ws.rs.core.Response.status

@ApiTokenAuth
@Path("webhook/git")
class BitbucketWebhookResource {

	@Inject BuildCycleManager buildManager

	@POST
	def Response push(String payload) {
		buildManager.startBuild
		return status(NO_CONTENT).build
	}

}
