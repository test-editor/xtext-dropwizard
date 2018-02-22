package org.testeditor.web.dropwizard.xtext.validation

import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException
import org.junit.Test

import static org.assertj.core.api.Assertions.*

class ValidationMarkerMapTest {

	@Test
	def void isEmptyInitially() {
		// given
		val unitUnderTest = new ValidationMarkerMap()

		// when
		val actual = unitUnderTest.allMarkers

		// then
		assertThat(actual).isEmpty
	}

	@Test
	def void containsValidationMarkersAfterUpdate() {
		// given
		val unitUnderTest = new ValidationMarkerMap()
		val expected = #[
			new ValidationSummary('path', 1, 2, 3),
			new ValidationSummary('another/path', 42, 23, 3)
		]
		unitUnderTest.updateMarkers(expected)

		// when
		val actual = unitUnderTest.allMarkers

		// then
		assertThat(actual).containsExactlyInAnyOrder(expected)
	}
	
	@Test
	def void returnsNoMarkersDefaultWhenPathIsNotFound() {
		// given
		val unitUnderTest = new ValidationMarkerMap()

		// when
		val actual = unitUnderTest.getMarker('unknown/path')

		// then
		assertThat(actual).isEqualTo(ValidationSummary.noMarkers('unknown/path'))
	}
	
	@Test
	def void retrievesValidationSummaryForPath() {
		// given
		val unitUnderTest = new ValidationMarkerMap()
		val containedSummaries = #[
			new ValidationSummary('path', 1, 2, 3),
			new ValidationSummary('another/path', 42, 23, 3)
		]
		unitUnderTest.updateMarkers(containedSummaries)

		// when
		val actual = unitUnderTest.getMarker('path')

		// then
		assertThat(actual).isEqualTo(containedSummaries.get(0))
	}

	@Test
	def void handlesEmptyUpdatesGracefully() {
		// given
		val unitUnderTest = new ValidationMarkerMap()
		val initialContent = #[
			new ValidationSummary('path', 1, 2, 3),
			new ValidationSummary('another/path', 42, 23, 3)
		]
		unitUnderTest.updateMarkers(initialContent)
		unitUnderTest.waitForUpdatedMarkers('session', 100)

		// when
		unitUnderTest.updateMarkers(null)

		// then
		assertThat(unitUnderTest.allMarkers).containsExactlyInAnyOrder(initialContent)
		try {
			unitUnderTest.waitForUpdatedMarkers('session', 50)
			fail('Expected operation to time out')
		} catch (TimeoutException e) {
		}
	}

	@Test
	def void waitsForFutureCompletionIfUpToDate() {
		// given
		val scheduler = Executors.newScheduledThreadPool(2)
		val session = 'session'
		val unitUnderTest = new ValidationMarkerMap()
		unitUnderTest.updateMarkers(#[])
		unitUnderTest.waitForUpdatedMarkers(session, 100)
		val expected = #[new ValidationSummary('path', 1, 2, 3)]

		// when
		val actual = scheduler.schedule([unitUnderTest.waitForUpdatedMarkers(session, 2000)], 1, TimeUnit.MILLISECONDS)
		scheduler.schedule([unitUnderTest.updateMarkers(expected)], 10, TimeUnit.MILLISECONDS).get

		// then
		assertThat(actual.get).containsExactlyInAnyOrder(expected)
	}

	@Test
	def void multipleClientswaitForFutureCompletionIfUpToDate() {
		// given
		val scheduler = Executors.newScheduledThreadPool(4)
		val sessions = #['session1', 'session2', 'session3', 'session4']
		val unitUnderTest = new ValidationMarkerMap()
		unitUnderTest.updateMarkers(#[])
		sessions.forEach[session|unitUnderTest.waitForUpdatedMarkers(session, 100)]

		val firstUpdate = #[new ValidationSummary('path', 1, 2, 3)]
		val secondUpdate = #[new ValidationSummary('different/path', 1, 2, 3)]
		val ScheduledFuture<Iterable<ValidationSummary>>[] actualFutures = newArrayOfSize(4)
		actualFutures.set(0, scheduler.schedule([unitUnderTest.waitForUpdatedMarkers(sessions.get(0), 2000)], 1, TimeUnit.MILLISECONDS))
		actualFutures.set(1, scheduler.schedule([unitUnderTest.waitForUpdatedMarkers(sessions.get(1), 2000)], 1, TimeUnit.MILLISECONDS))
		actualFutures.set(2, scheduler.schedule([unitUnderTest.waitForUpdatedMarkers(sessions.get(2), 2000)], 1, TimeUnit.MILLISECONDS))
		actualFutures.set(3, scheduler.schedule([unitUnderTest.waitForUpdatedMarkers(sessions.get(3), 2000)], 250, TimeUnit.MILLISECONDS))
		val firstUpdateFuture = scheduler.schedule([unitUnderTest.updateMarkers(firstUpdate)], 100, TimeUnit.MILLISECONDS)
		val secondUpdateFuture = scheduler.schedule([unitUnderTest.updateMarkers(secondUpdate)], 200, TimeUnit.MILLISECONDS)

		// when
		firstUpdateFuture.get

		// then
		assertThat(actualFutures.get(0).get).containsExactlyInAnyOrder(firstUpdate)
		assertThat(actualFutures.get(1).get).containsExactlyInAnyOrder(firstUpdate)

		secondUpdateFuture.get

		assertThat(actualFutures.get(2).get).containsAll(firstUpdate)
		assertThat(actualFutures.get(2).get).containsAll(secondUpdate)
		actualFutures.get(3).get
		try {
			unitUnderTest.waitForUpdatedMarkers(sessions.get(3), 50)
			fail('Expected operation to time out')
		} catch (TimeoutException e) {
		}
	}

}
