package org.testeditor.web.dropwizard.xtext.validation

import java.nio.file.Path
import java.nio.file.Paths
import java.util.ArrayList
import java.util.HashMap
import javax.inject.Inject
import javax.inject.Singleton
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.builder.standalone.IIssueHandler
import org.eclipse.xtext.validation.Issue
import org.slf4j.LoggerFactory

@Singleton
class ValidationMarkerUpdater implements IIssueHandler {

	@Inject DefaultIssueHandler delegateForDefaultBehavior
	@Inject extension ValidationMarkerMap validationMarkerMap

	static val logger = LoggerFactory.getLogger(ValidationMarkerUpdater)

	val collectedValidationSummaries = new HashMap<String, ValidationSummary>()
	var Path rootDirectory
	var Resource currentResource

	def void init(String rootDirectory) {
		this.rootDirectory = Paths.get(rootDirectory)
	}

	def setContext(Resource resource) {
		currentResource = resource
	}

	override handleIssue(Iterable<Issue> issues) {
		if (issues !== null && issues.length > 0) {
			issues.forEach [
				val path = uriToProblem.resourcePath
				if (path !== null) {
					previouslyCollectedSummary(path).incrementFor(it)
				} else {
					logger.warn('''Could not determine resource path for issue: «it»''')
				}
			]
		}
		return delegateForDefaultBehavior.handleIssue(issues)
	}

	def updateMarkerMap() {
		if (!collectedValidationSummaries.empty) {
			updateMarkers(new ArrayList(collectedValidationSummaries.values))
			collectedValidationSummaries.clear
		}
	}

	private def previouslyCollectedSummary(String path) {
		collectedValidationSummaries.computeIfAbsent(path, [ValidationSummary.noMarkers(path)])
	}

	private def incrementFor(ValidationSummary summary, Issue issue) {
		summary => [
			switch (issue.severity) {
				case ERROR:
					errors = errors + 1
				case WARNING:
					warnings = warnings + 1
				case INFO:
					infos = infos + 1
				case IGNORE: {
				}
			}
		]
	}

	private def getResourcePath(URI uri) {
		if (uri !== null) {
			return rootDirectory.relativize(Paths.get(uri.path)).toString
		} else if (currentResource !== null) {
			return rootDirectory.relativize(Paths.get(currentResource.URI.path)).toString
		} else {
			return null
		}
	}

}
