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

	static val SESSION_UPDATE_CACHE_TIMEOUT_SECONDS = 5 * 60
	static val logger = LoggerFactory.getLogger(ValidationMarkerUpdater)

	val validationMarkers = new ConcurrentHashMap<String, ValidationSummary>()
	val lastUpdated = new AtomicLong(System.currentTimeMillis)
	val sessionUpdated = CacheBuilder.newBuilder.expireAfterAccess(SESSION_UPDATE_CACHE_TIMEOUT_SECONDS, SECONDS).<String, Long>build
	var futureUpdate = new CompletableFuture<Iterable<ValidationSummary>>()

	def void updateMarkers(Iterable<ValidationSummary> summaries) {
		if (summaries !== null && summaries.length > 0) {
			val currentUpdate = futureUpdate
			summaries.forEach[summary|validationMarkers.put(summary.path, summary)]
			futureUpdate = new CompletableFuture<Iterable<ValidationSummary>>()
			currentUpdate.complete(allMarkers)
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

	def waitForUpdatedMarkers(String session, long timeoutMillis) {
		var Iterable<ValidationSummary> result
		result = if (session.isUpToDate) {
			futureUpdate.get(timeoutMillis, MILLISECONDS)
		} else {
			allMarkers
		}
		sessionUpdated.put(session, System.currentTimeMillis)
		return result
	}

	private def isUpToDate(String session) {
		return sessionUpdated.asMap.getOrDefault(session, -1L) >= lastUpdated.get
	}

}
