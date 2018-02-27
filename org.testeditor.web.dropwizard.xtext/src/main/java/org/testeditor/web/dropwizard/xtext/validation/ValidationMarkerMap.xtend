package org.testeditor.web.dropwizard.xtext.validation

import com.google.common.cache.CacheBuilder
import java.util.concurrent.CompletableFuture
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong
import javax.inject.Singleton
import org.slf4j.LoggerFactory

import static java.util.concurrent.TimeUnit.*

@Singleton
class ValidationMarkerMap {
	static val logger = LoggerFactory.getLogger(ValidationMarkerUpdater)

	val validationMarkers = new ConcurrentHashMap<String, ValidationSummary>()
	val lastUpdated = new AtomicLong(System.currentTimeMillis)
	var futureUpdate = new CompletableFuture<Iterable<ValidationSummary>>()
	
	def long getLastUpdated() {
		return lastUpdated.get
	}

	def void updateMarkers(Iterable<ValidationSummary> summaries) {
		if (summaries !== null && summaries.length > 0) {
			val currentUpdate = futureUpdate
			summaries.forEach[summary|validationMarkers.put(summary.path, summary)]
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

	def waitForUpdatedMarkers(long lastAccessed, long timeoutMillis) {
		var Iterable<ValidationSummary> result
		result = if (isUpToDateSince(lastAccessed)) {
			futureUpdate.get(timeoutMillis, MILLISECONDS)
		} else {
			allMarkers
		}
		return result
	}

	private def isUpToDateSince(long lastAccessed) {
		logger.info('''validation was last updated at "«lastUpdated.get»", last checked for updates at "«lastAccessed»"''')
		return lastAccessed >= lastUpdated.get
	}

}
