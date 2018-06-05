package org.testeditor.web.dropwizard.xtext.validation

import com.google.inject.Provider
import org.eclipse.emf.common.util.URI
import org.eclipse.xtext.diagnostics.Severity
import org.eclipse.xtext.validation.Issue
import org.eclipse.xtext.validation.Issue.IssueImpl
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import org.junit.runners.Parameterized.Parameters
import org.mockito.ArgumentCaptor
import org.mockito.Captor
import org.mockito.InjectMocks
import org.mockito.Mock
import org.mockito.MockitoAnnotations
import org.testeditor.web.dropwizard.xtext.XtextConfiguration

import static java.util.Collections.nCopies
import static org.assertj.core.api.Assertions.assertThat
import static org.eclipse.xtext.diagnostics.Severity.*
import static org.mockito.Mockito.verify
import static org.mockito.Mockito.when

@RunWith(Parameterized)
class ValidationMarkerUpdaterTest {

	static val rootPath = '/root/'
	static val samplePath = 'path/to/file.ext'
	static val sampleURI = URI.createFileURI(rootPath + samplePath)

	@Parameters(name = '{0}')
	static def Iterable<Object[]> testVectors() {
		return #[
			#['should handle empty issue list with empty validation summary to remove issues', 
				sampleURI, #[], #[new ValidationSummary(samplePath, 0, 0, 0)]
			],
			#['should add up error issues for single resource', 
				sampleURI, nCopies(10, issueFor(sampleURI, ERROR)), #[new ValidationSummary(samplePath, 10, 0, 0)]
			],
			#['should add up warning issues for single resource', 
				sampleURI, nCopies(10, issueFor(sampleURI, WARNING)), #[new ValidationSummary(samplePath, 0, 10, 0)]
			],
			#['should add up info issues for single resource', 
				sampleURI, nCopies(10, issueFor(sampleURI, INFO)), #[new ValidationSummary(samplePath, 0, 0, 10)]
			],
			#['should not consider ignore issues for single resource', 
				sampleURI, nCopies(10, issueFor(sampleURI, IGNORE)), #[new ValidationSummary(samplePath, 0, 0, 0)]
			],
			#['should add up issues by type for single resource', 
				sampleURI, #[issueFor(sampleURI, ERROR),
				issueFor(sampleURI, WARNING),
				issueFor(sampleURI, ERROR),
				issueFor(sampleURI, INFO),
				issueFor(sampleURI, IGNORE)],
				#[new ValidationSummary(samplePath, 2, 1, 1)]
			]
		]
	}

	var Iterable<Issue> givenIssues
	var URI resourceURI
	var ValidationSummary[] expectedSummaries

	new(String testName, URI resourceURI, Iterable<Issue> givenIssues, Iterable<ValidationSummary> expectedSummaries) {
		this.resourceURI = resourceURI
		this.givenIssues = givenIssues
		this.expectedSummaries = expectedSummaries
	}

	@Before
	def void initMocks() {
		MockitoAnnotations.initMocks(this);
	}

	@Mock ValidationMarkerMap markerMap
	@Mock Provider<XtextConfiguration> configProvider
	@InjectMocks ValidationMarkerUpdater markerUpdaterUnderTest
	
	@Captor ArgumentCaptor<Iterable<ValidationSummary>> actualSummaries

	@Test
	def void returnsMarkerSummary() {
		// given
		val config = new XtextConfiguration => [
			localRepoFileRoot = rootPath
		]
		when(configProvider.get).thenReturn(config)

		// when
		markerUpdaterUnderTest.afterValidate(resourceURI, givenIssues)
		markerUpdaterUnderTest.updateMarkerMap

		// then
		verify(markerMap).updateMarkers(actualSummaries.capture())
		assertThat(actualSummaries.value).containsExactlyInAnyOrder(expectedSummaries)
	}

	private static def Issue issueFor(URI uri, Severity type) {
		return new IssueImpl() => [
			uriToProblem = uri
			severity = type
		]
	}

}
