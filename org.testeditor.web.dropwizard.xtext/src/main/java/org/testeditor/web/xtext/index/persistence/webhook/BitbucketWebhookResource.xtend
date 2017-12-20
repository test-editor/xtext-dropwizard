package org.testeditor.web.xtext.index.persistence.webhook

import javax.inject.Inject
import javax.ws.rs.POST
import javax.ws.rs.Path
import javax.ws.rs.core.Response
import org.testeditor.web.dropwizard.auth.ApiTokenAuth
import org.testeditor.web.xtext.index.persistence.GitService
import org.testeditor.web.xtext.index.persistence.IndexUpdater

import static javax.ws.rs.core.Response.Status.*
import static javax.ws.rs.core.Response.status

@ApiTokenAuth
@Path("webhook/git")
class BitbucketWebhookResource {

	@Inject GitService gitService
	@Inject IndexUpdater indexUpdater

	@POST
	def Response push(String payload) {
		val oldHead = gitService.headTree
		gitService.pull
		val newHead = gitService.headTree
		if (oldHead != newHead) {
			invokeIndexUpdate(oldHead.name(), newHead.name())
		}
		return status(NO_CONTENT).build
	}

	private def void invokeIndexUpdate(String oldHeadCommit, String newHeadCommit) {
		val diff = gitService.calculateDiff(oldHeadCommit, newHeadCommit)
		val root = gitService.projectFolder
		indexUpdater.updateIndex(root, diff)
	}

}
