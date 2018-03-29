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
		val unitUnderTest = new ValidationMarkerMap

		// when
		val actual = unitUnderTest.allMarkers

		// then
		assertThat(actual).isEmpty
	}

	@Test
	def void containsValidationMarkersAfterUpdate() {
		// given
		val unitUnderTest = new ValidationMarkerMap
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
	def void removesValidationMarkersAfterUpdateWithNullSummary() {
		// given
		val unitUnderTest = new ValidationMarkerMap
		val initialSummaries = #[
			new ValidationSummary('path', 1, 2, 3),
			new ValidationSummary('another/path', 42, 23, 3)
		]
		val summariesAfterFix = #[
			new ValidationSummary('path', 0, 0, 0)
		]
		unitUnderTest.updateMarkers(initialSummaries)
		assertThat(unitUnderTest.allMarkers).containsExactlyInAnyOrder(initialSummaries)
		
		// when
		unitUnderTest.updateMarkers(summariesAfterFix)

		// then
		assertThat(unitUnderTest.allMarkers).containsExactlyInAnyOrder(#[new ValidationSummary('another/path', 42, 23, 3)])
	}

	@Test
	def void returnsNoMarkersDefaultWhenPathIsNotFound() {
		// given
		val unitUnderTest = new ValidationMarkerMap

		// when
		val actual = unitUnderTest.getMarker('unknown/path')

		// then
		assertThat(actual).isEqualTo(ValidationSummary.noMarkers('unknown/path'))
	}

	@Test
	def void retrievesValidationSummaryForPath() {
		// given
		val unitUnderTest = new ValidationMarkerMap
		val containedSummaries = #[
			new ValidationSummary('path', 1, 2, 3),
			new ValidationSummary('another/path', 42, 23, 3)
		]
		unitUnderTest.updateMarkers(containedSummaries)

		// when
		val actual = unitUnderTest.getMarker('path')

		// then
		assertThat(actual).isEqualTo(containedSummaries.head)
	}

	@Test
	def void handlesEmptyUpdatesGracefully() {
		// given
		val unitUnderTest = new ValidationMarkerMap
		val initialContent = #[
			new ValidationSummary('path', 1, 2, 3),
			new ValidationSummary('another/path', 42, 23, 3)
		]
		unitUnderTest.updateMarkers(initialContent)
		unitUnderTest.waitForAnyNewMarkersSince(-1, 100)
		val lastUpdatedBefore = unitUnderTest.lastUpdated

		// when
		unitUnderTest.updateMarkers(#[])

		// then
		assertThat(unitUnderTest.allMarkers).containsExactlyInAnyOrder(initialContent)
		assertThat(unitUnderTest.lastUpdated).isEqualTo(lastUpdatedBefore)
	}

	@Test
	def void waitsForFutureCompletionIfUpToDate() {
		// given
		val scheduler = Executors.newScheduledThreadPool(2)
		val unitUnderTest = new ValidationMarkerMap
		unitUnderTest.updateMarkers(#[])
		unitUnderTest.waitForAnyNewMarkersSince(-1, 100)
		val expected = #[new ValidationSummary('path', 1, 2, 3)]
		val upToDate = System.currentTimeMillis + 5000L

		// when
		val actual = scheduler.schedule([unitUnderTest.waitForAnyNewMarkersSince(upToDate, 2000)], 1, TimeUnit.MILLISECONDS)
		scheduler.schedule([unitUnderTest.updateMarkers(expected)], 10, TimeUnit.MILLISECONDS).get

		// then
		assertThat(actual.get).containsExactlyInAnyOrder(expected)
	}

	@Test
	def void multipleClientswaitForFutureCompletionIfUpToDate() {
		// given
		val scheduler = Executors.newScheduledThreadPool(4)
		val unitUnderTest = new ValidationMarkerMap
		unitUnderTest.updateMarkers(#[])

		val firstUpdate = #[new ValidationSummary('path', 1, 2, 3)]
		val secondUpdate = #[new ValidationSummary('different/path', 1, 2, 3)]
		val ScheduledFuture<Iterable<ValidationSummary>>[] actualFutures = newArrayOfSize(4)
		actualFutures.set(0, scheduler.schedule([unitUnderTest.waitForAnyNewMarkersSince(-1L, 2000)], 1, TimeUnit.MILLISECONDS))
		actualFutures.set(1, scheduler.schedule([unitUnderTest.waitForAnyNewMarkersSince(-1L, 2000)], 1, TimeUnit.MILLISECONDS))
		actualFutures.set(2, scheduler.schedule([unitUnderTest.waitForAnyNewMarkersSince(-1L, 2000)], 1, TimeUnit.MILLISECONDS))
		actualFutures.set(3, scheduler.schedule([unitUnderTest.waitForAnyNewMarkersSince(-1L, 2000)], 250, TimeUnit.MILLISECONDS))
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
			unitUnderTest.waitForAnyNewMarkersSince(System.currentTimeMillis + 5000, 50)
			fail('Expected operation to time out')
		} catch (TimeoutException e) {
		}
	}

}
