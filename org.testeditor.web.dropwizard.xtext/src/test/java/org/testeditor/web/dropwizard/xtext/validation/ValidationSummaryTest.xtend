package org.testeditor.web.dropwizard.xtext.validation

import io.dropwizard.jackson.Jackson
import org.junit.Test

import static io.dropwizard.testing.FixtureHelpers.fixture
import static org.assertj.core.api.Assertions.assertThat

class ValidationSummaryTest {
	
	static val MAPPER = Jackson.newObjectMapper();
	static val VALIDATION_SUMMARY_JSON = fixture("fixtures/sample-validation-summary.json")

    @Test
    def void serializesToJSON() {
    	// given
    	val validationSummaryToSerialize = new ValidationSummary('sample/path', 1, 2, 3)
        val expectedJSON = MAPPER.writeValueAsString(MAPPER.readValue(VALIDATION_SUMMARY_JSON, ValidationSummary));
    	
    	// when
    	val actualJSON = MAPPER.writeValueAsString(validationSummaryToSerialize)
    	
    	// then
    	assertThat(actualJSON).isEqualTo(expectedJSON)
    }
    
    @Test
    def void deserializesFromJSON() {
    	// given
    	val jsonToDeserialize = VALIDATION_SUMMARY_JSON
        val expectedValidationSummary = new ValidationSummary('sample/path', 1, 2, 3)
        
        // when
        val actualValidationSummary = MAPPER.readValue(jsonToDeserialize, ValidationSummary)
        
        // then
        assertThat(actualValidationSummary).isEqualTo(expectedValidationSummary);
    }
	
}
