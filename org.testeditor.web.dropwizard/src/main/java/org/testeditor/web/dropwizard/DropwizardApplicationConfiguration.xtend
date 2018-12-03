package org.testeditor.web.dropwizard

import com.fasterxml.jackson.annotation.JsonProperty
import io.dropwizard.Configuration

class DropwizardApplicationConfiguration extends Configuration {
 
      String apiToken
      String applicationId
 
      @JsonProperty
      def String getApiToken() {
          return this.apiToken
      }
 
      @JsonProperty
      def void setApiToken(String apiToken) {
         this.apiToken = apiToken
      }
 
      @JsonProperty
      def String getApplicationId() {
          return this.applicationId
      }
 
      @JsonProperty
      def void setApplicationId(String applicationId) {
         this.applicationId = applicationId
      }

}
