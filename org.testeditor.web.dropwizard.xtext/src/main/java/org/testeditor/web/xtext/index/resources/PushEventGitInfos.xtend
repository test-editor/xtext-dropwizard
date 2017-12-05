package org.testeditor.web.xtext.index.resources

import org.eclipse.xtext.util.Pair
import org.eclipse.xtext.util.Tuples
import com.fasterxml.jackson.databind.JsonNode

/**
 * Information from json payload of a push event
 */
class PushEventGitInfos {

	def boolean isPushEvent(RepoEvent repoEvent) {
		val changes = repoEvent.nativeEventPayload.get("push")?.get("changes") ?: emptyList
		return changes.size > 0
	}

	def Pair<String, String> getOldNewHeadCommitIds(RepoEvent repoEvent) {
		val change = repoEvent.nativeEventPayload.get("push")?.get("changes")?.head
		val oldCommit = change.getAsString("old", "target", "hash")
		val newCommit = change.getAsString("new", "target", "hash")
		return Tuples.create(oldCommit, newCommit)
	}

	/**
	 * retrieve a string within deep structured json by repeatedly executing node.get(next-segment)
	 */
	private def String getAsString(JsonNode rootNode, String ... segments) {
		segments.fold(rootNode) [ node, segment |
			node?.get(segment)
		]?.asText
	}

}
