package org.testeditor.web.dropwizard.xtext.validation

import java.io.File
import java.nio.file.Path
import java.nio.file.Paths
import java.util.ArrayList
import java.util.HashMap
import javax.inject.Inject
import javax.inject.Singleton
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.build.BuildRequest.IPostValidationCallback
import org.eclipse.xtext.builder.standalone.IIssueHandler
import org.eclipse.xtext.builder.standalone.StandaloneBuilder
import org.eclipse.xtext.validation.Issue
import org.slf4j.LoggerFactory

/**
 * Collects and summarizes validation issues on a per-resource-basis.
 * 
 * This class is an {@link IIssueHandler},
 * so when bound via Guice, it will be used by the {@link StandaloneBuilder}
 * as a callback invoked after validating each resource.
 * 
 * This updater in turn sends the summarized validation results to a
 * {@link ValidationMarkerMap},
 * but only after the builder has finished validating all resources. Since the
 * latter does not offer appropriate callback hooks, 
 * {@link org.testeditor.web.xtext.index.CustomStandaloneBuilder} extends that
 * class, and calls this updater's {@link #updateMarkerMap) after the build is
 * complete.
 * 
 * While the mode of usage by the builder means that all issues passed to 
 * {@link #handleIssue} will refer to the same resource, the method is, in
 * theory, able to handle a mixed set of issues belonging to arbitrary
 * resources. Unfortunately, not all validators produce issues with a non-null
 * resource URI set, so as a fallback, the context resource can be explicitly
 * set with {@link #setContext}, and its URI will be used to construct a
 * resource path string for any issue that lacks the necessary information
 * itself. 
 */
@Singleton
class ValidationMarkerUpdater implements IIssueHandler, IPostValidationCallback {

	@Inject DefaultIssueHandler delegateForDefaultBehavior
	@Inject extension ValidationMarkerMap validationMarkerMap

	static val logger = LoggerFactory.getLogger(ValidationMarkerUpdater)

	val collectedValidationSummaries = new HashMap<String, ValidationSummary>()
	var Path rootDirectory
	var Resource currentResource

	def void init(String rootDirectory) {
		this.rootDirectory = new File(rootDirectory).absoluteFile.toPath
	}

	def void setContext(Resource resource) {
		currentResource = resource
	}

	override afterValidate(URI resourceURI, Iterable<Issue> issues) {
		issues.forEach[previouslyCollectedSummary(resourceURI.toResourcePath).incrementFor(it)]
		return true
	}

	override boolean handleIssue(Iterable<Issue> issues) {
		issues?.forEach [
			val path = uriToProblem.toResourcePath
			if (path !== null) {
				previouslyCollectedSummary(path).incrementFor(it)
			} else {
				logger.warn('''Could not determine resource path for issue: «it»''')
			}
		]
		return delegateForDefaultBehavior.handleIssue(issues)
	}

	def void updateMarkerMap() {
		updateMarkers(new ArrayList(collectedValidationSummaries.values))
		collectedValidationSummaries.clear
	}

	private def previouslyCollectedSummary(String path) {
		return collectedValidationSummaries.computeIfAbsent(path, [ValidationSummary.noMarkers(path)])
	}

	private def incrementFor(ValidationSummary summary, Issue issue) {
		return summary => [
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

	private def toResourcePath(URI uri) {
		if (uri !== null) {
			return rootDirectory.relativize(Paths.get(uri.path)).toString
		} else if (currentResource !== null) {
			return rootDirectory.relativize(Paths.get(currentResource.URI.path)).toString
		} else {
			return null
		}
	}

}
