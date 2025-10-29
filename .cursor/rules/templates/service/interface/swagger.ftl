openapi: 3.0.3
info:
  title: ${serviceName} API
  description: API documentation for the ${serviceName} service
  version: 1.0.0
  contact:
    name: DoorSync Team
    email: support@DoorSync.com
servers:
  - url: https://api.DoorSync.com/{stage}/api/v1/${serviceName}
    description: ${serviceName} API (v1)
    variables:
      stage:
        enum:
          - dev
          - test
          - prod
        default: dev
        description: Environment stage
paths:
<#list endpoints as endpoint>
  ${endpoint.path}:
    ${endpoint.method?lower_case}:
      summary: ${endpoint.summary}
      description: |
        ${endpoint.description}
      operationId: ${endpoint.operationId}
      tags:
        - ${endpoint.tag}
      <#if endpoint.authRequired?? && endpoint.authRequired>
      security:
        - BearerAuth: []
      </#if>
      <#if (endpoint.method?upper_case == "POST" || endpoint.method?upper_case == "PUT" || endpoint.method?upper_case == "PATCH") || (endpoint.requestSchema??)>
      requestBody:
        required: ${endpoint.requestRequired!true}
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/${endpoint.requestSchema}'
      </#if>
      <#if endpoint.parameters?? && (endpoint.parameters?size > 0)>
      parameters:
      <#list endpoint.parameters as p>
        - in: ${p.in}
          name: ${p.name}
          required: ${p.required!false}
          schema:
            type: ${p.type}
            <#if p.format??>format: ${p.format}</#if>
          <#if p.description??>description: ${p.description}</#if>
      </#list>
      </#if>
      responses:
         '${endpoint.successStatus!"200"}':
          description: Successful operation
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/${endpoint.responseSchema}'
           headers:
             X-Correlation-Id:
               description: Correlation ID for request tracing
               schema:
                 type: string
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '403':
          $ref: '#/components/responses/Forbidden'
        '404':
          $ref: '#/components/responses/NotFound'
        '409':
          $ref: '#/components/responses/Conflict'
        '500':
          $ref: '#/components/responses/ServerError'

</#list>
components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
  
  schemas:
<#list schemas as schema>
    ${schema.name}:
      type: ${schema.type}
      <#if schema.required?size gt 0>
      required:
      <#list schema.required as requiredProp>
        - ${requiredProp}
      </#list>
      </#if>
      <#if schema.type == "object">
      properties:
      <#list schema.properties as prop>
        ${prop.name}:
          type: ${prop.type}
          <#if prop.format??>
          format: ${prop.format}
          </#if>
          <#if prop.description??>
          description: ${prop.description}
          </#if>
          <#if prop.minimum??>
          minimum: ${prop.minimum}
          </#if>
          <#if prop.maximum??>
          maximum: ${prop.maximum}
          </#if>
          <#if prop.minLength??>
          minLength: ${prop.minLength}
          </#if>
          <#if prop.maxLength??>
          maxLength: ${prop.maxLength}
          </#if>
          <#if prop.enum??>
          enum:
          <#list prop.enum as enumValue>
            - ${enumValue}
          </#list>
          </#if>
          <#if prop.nullable?? && prop.nullable>
          nullable: true
          </#if>
          <#if prop.items??>
          items:
            <#if prop.items.ref??>
            $ref: ${prop.items.ref}
            <#else>
            type: ${prop.items.type}
            <#if prop.items.format??>
            format: ${prop.items.format}
            </#if>
            </#if>
          </#if>
          <#if prop.ref??>
          $ref: ${prop.ref}
          </#if>
      </#list>
      </#if>
      <#if schema.items??>
      items:
        <#if schema.items.ref??>
        $ref: ${schema.items.ref}
        <#else>
        type: ${schema.items.type}
        <#if schema.items.format??>
        format: ${schema.items.format}
        </#if>
        </#if>
      </#if>

</#list>
    ErrorResponse:
      type: object
      required:
        - error
        - metadata
      properties:
        error:
          type: object
          required:
            - code
            - message
          properties:
            code:
              type: string
              description: Error code
              example: "VALIDATION_ERROR"
            message:
              type: string
              description: Error message
              example: "Validation failed for the request"
            details:
              type: array
              items:
                type: object
                properties:
                  field:
                    type: string
                    description: Field with error
                    example: "email"
                  message:
                    type: string
                    description: Error message for the field
                    example: "Must be a valid email address"
        metadata:
          type: object
          required:
            - timestamp
            - correlationId
            - path
          properties:
            timestamp:
              type: string
              format: date-time
              description: Timestamp when the error occurred
              example: "2023-07-19T12:34:56Z"
            correlationId:
              type: string
              description: ID for correlating the request across services
              example: "correlation-789"
            path:
              type: string
              description: Path where the error occurred
              example: "/api/users"

  responses:
    BadRequest:
      description: Invalid request
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
      headers:
        X-Correlation-Id:
          description: Correlation ID for request tracing
          schema:
            type: string
    Unauthorized:
      description: Authentication required
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
      headers:
        X-Correlation-Id:
          description: Correlation ID for request tracing
          schema:
            type: string
    Forbidden:
      description: Permission denied
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
      headers:
        X-Correlation-Id:
          description: Correlation ID for request tracing
          schema:
            type: string
    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
      headers:
        X-Correlation-Id:
          description: Correlation ID for request tracing
          schema:
            type: string
    Conflict:
      description: Business rule violation
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
      headers:
        X-Correlation-Id:
          description: Correlation ID for request tracing
          schema:
            type: string
    ServerError:
      description: Unexpected server error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse' 
      headers:
        X-Correlation-Id:
          description: Correlation ID for request tracing
          schema:
            type: string