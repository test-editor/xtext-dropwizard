package org.testeditor.web.dropwizard.xtext.validation

import java.util.concurrent.CompletableFuture
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.TimeoutException
import java.util.concurrent.atomic.AtomicLong
import javax.inject.Singleton
import org.slf4j.LoggerFactory

import static java.util.concurrent.TimeUnit.*

@Singleton
class ValidationMarkerMap {
	static val MAX_MARKERS = 1000
	static val logger = LoggerFactory.getLogger(ValidationMarkerUpdater)

	val validationMarkers = new ConcurrentHashMap<String, ValidationSummary>()
	val lastUpdated = new AtomicLong(System.currentTimeMillis)
	var futureUpdate = new CompletableFuture<Iterable<ValidationSummary>>()

	def long getLastUpdated() {
		return lastUpdated.get
	}

	def void updateMarkers(Iterable<ValidationSummary> summaries) {
		if (!summaries.empty) {
			val currentUpdate = futureUpdate
			summaries.groupBy[hasNoIssues] => [
				val summariesWithoutIssues = getOrDefault(true, #[])
				val summariesWithIssues = getOrDefault(false, #[])
				summariesWithoutIssues.forEach[validationMarkers.remove(path)]
				val remainingSpace = Math.max(0, MAX_MARKERS - validationMarkers.size)
				summariesWithIssues.take(remainingSpace).forEach[validationMarkers.put(path, it)]
				if (summariesWithIssues.size > remainingSpace) {
					logger.warn('''Too many issues! Validation results were capped at «MAX_MARKERS» issues.''')
				}
			]
			futureUpdate = new CompletableFuture<Iterable<ValidationSummary>>()
			currentUpdate.complete(allMarkers)
			val now = System.currentTimeMillis
			logger.info('''Validation markers were updated (timestamp: «now»)''')
			lastUpdated.set(System.currentTimeMillis)
		}
	}

	def ValidationSummary getMarker(String path) {
		return if (validationMarkers.containsKey(path)) {
			validationMarkers.get(path)
		} else {
			logger.info('''Path not found: "«path»"''')
			ValidationSummary.noMarkers(path)
		}
	}

	def Iterable<ValidationSummary> getAllMarkers() {
		return validationMarkers.values
	}

	def Iterable<ValidationSummary> waitForAnyNewMarkersSince(long lastAccessed, long timeoutMillis) throws TimeoutException {
		return if (newMarkersAvailableSince(lastAccessed)) {
			allMarkers
		} else {
			futureUpdate.get(timeoutMillis, MILLISECONDS)
		}
	}

	private def newMarkersAvailableSince(long lastAccessed) {
		return lastAccessed <= lastUpdated.get
	}

	private def hasNoIssues(ValidationSummary summary) {
		return summary.errors === 0 && summary.warnings === 0 && summary.infos === 0
	}

}
