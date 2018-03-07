package org.testeditor.web.dropwizard.xtext.validation

import org.eclipse.emf.common.util.URI
import org.eclipse.xtext.builder.standalone.IIssueHandler.DefaultIssueHandler
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

import static java.util.Collections.nCopies
import static org.assertj.core.api.Assertions.assertThat
import static org.eclipse.xtext.diagnostics.Severity.*
import static org.mockito.Mockito.verify

@RunWith(Parameterized)
class ValidationMarkerUpdaterTest {

	static val rootPath = '/root/'
	static val samplePath = 'path/to/file.ext'
	static val anotherPath = 'path/to/another/different-file'
	static val sampleURI = URI.createFileURI(rootPath + samplePath)
	static val anotherURI = URI.createFileURI(rootPath + anotherPath)
	static val sampleURIWithFragment = URI.createURI(rootPath + samplePath + '#fragment')

	@Parameters(name = '{0}')
	static def Iterable<Object[]> testVectors() {
		return #[
			#['should handle empty issue list with default behavior', #[], #[]],
			#['should add up error issues for single resource', 
				nCopies(10, issueFor(sampleURI, ERROR)), #[new ValidationSummary(samplePath, 10, 0, 0)]
			],
			#['should add up warning issues for single resource', 
				nCopies(10, issueFor(sampleURI, WARNING)), #[new ValidationSummary(samplePath, 0, 10, 0)]
			],
			#['should add up info issues for single resource', 
				nCopies(10, issueFor(sampleURI, INFO)), #[new ValidationSummary(samplePath, 0, 0, 10)]
			],
			#['should not consider ignore issues for single resource', 
				nCopies(10, issueFor(sampleURI, IGNORE)), #[new ValidationSummary(samplePath, 0, 0, 0)]
			],
			#['should add up issues by type for single resource', 
				#[issueFor(sampleURI, ERROR),
				issueFor(sampleURI, WARNING),
				issueFor(sampleURI, ERROR),
				issueFor(sampleURI, INFO),
				issueFor(sampleURI, IGNORE)],
				#[new ValidationSummary(samplePath, 2, 1, 1)]
			],
			#['should add up issues by type, individually for each resource',
				#[issueFor(sampleURI, ERROR),
				issueFor(anotherURI, WARNING),
				issueFor(sampleURIWithFragment, INFO),
				issueFor(anotherURI, IGNORE),
				issueFor(anotherURI, WARNING)],
				#[new ValidationSummary(samplePath, 1, 0, 1), new ValidationSummary(anotherPath, 0, 2, 0)]
			]
		]
	}

	var Iterable<Issue> givenIssues
	var ValidationSummary[] expectedSummaries

	new(String testName, Iterable<Issue> givenIssues, Iterable<ValidationSummary> expectedSummaries) {
		this.givenIssues = givenIssues
		this.expectedSummaries = expectedSummaries
	}

	@Before
	def void initMocks() {
		MockitoAnnotations.initMocks(this);
	}

	@Mock DefaultIssueHandler defaultHandler
	@Mock ValidationMarkerMap markerMap
	@InjectMocks ValidationMarkerUpdater markerUpdaterUnderTest
	
	@Captor ArgumentCaptor<Iterable<ValidationSummary>> actualSummaries
	@Captor ArgumentCaptor<Iterable<Issue>> actualIssues

	@Test
	def void returnsMarkerSummary() {
		// given
		markerUpdaterUnderTest.init(rootPath)

		// when
		markerUpdaterUnderTest.handleIssue(givenIssues)
		markerUpdaterUnderTest.updateMarkerMap

		// then
		verify(markerMap).updateMarkers(actualSummaries.capture())
		assertThat(actualSummaries.value).containsExactlyInAnyOrder(expectedSummaries)

		verify(defaultHandler).handleIssue(actualIssues.capture())
		assertThat(actualIssues.value).isSameAs(givenIssues)
	}

	private static def Issue issueFor(URI uri, Severity type) {
		return new IssueImpl() => [
			uriToProblem = uri
			severity = type
		]
	}

}
