;; Structurizr C4 DSL TreeSitter Queries for syntax highlighting
;; This file contains base syntax highlighting for Structurizr C4 diagrams
;; Additional context-aware highlighting is provided by the structurizr_highlight_fix.lua plugin

;; Main keywords and declarations
[
  "workspace"
  "model"
  "views"
  "configuration"
  "properties"
  "styles"
  "themes"
  "!include"
  "!script"
  "!plugin"
  "!identifiers"
  "!impliedRelationships"
] @keyword

;; Specifically highlight "element" as a keyword
"element" @keyword.element

;; Element types with specific captures for consistent coloring
"softwareSystem" @type.softwareSystem
"system" @type.system
"container" @type.container
"component" @type.component
"person" @type.person
"enterprise" @type.enterprise
"actor" @type.actor
"service" @type.service
"database" @type.database
"queue" @type.queue

;; Other element types
[
  "deploymentEnvironment"
  "deploymentNode"
  "deploymentGroup"
  "infrastructureNode"
  "softwareSystemInstance"
  "containerInstance"
  "boundary"
] @type

;; Relationship keywords
[
  "relationship"
  "relationships"
] @type

;; Group keywords 
[
  "group"
  "groups"
  "instances"
] @type

;; View types with specific captures for consistent coloring
"systemLandscape" @function.systemLandscape
"systemContext" @function.systemContext
"dynamic" @function.dynamic
"deployment" @function.deployment
"filtered" @function.filtered
"custom" @function.custom
"image" @function.image

;; Properties and attributes
[
  ; Basic properties
  "description"
  "technology"
  "url"
  "title"
  
  ; Layout and visual properties
  "autoLayout"
  "include"
  "exclude"
  "animation"
  "theme"
  "tags"
  "tag"
  "shape"
  "icon"
  "width"
  "height"
  "thickness"
  "background"
  "color"
  "fontSize"
  "stroke"
  "border"
  "position"
  "opacity"
  
  ; Structural properties
  "elements"
  "style"
  "styles"
  "properties"
  "uses"
  "delivers"
  "vertices"
  "routing"
  "perspective"
  "perspectives"
  "display"
  "filter"
  "key"
  "scope"
  "visibility"
  "users"
  "instances"
] @property

;; String literals
(string) @string

;; Comments
(line_comment) @comment
(block_comment) @comment

;; Identifiers
(identifier) @variable
(dotted_identifier) @variable.member
(relation_identifier) @variable.member
(wildcard_identifier) @variable.builtin

;; Relations
["->" "<-" "<->"] @operator

;; Brackets and delimiters
["(" ")" "{" "}" "[" "]"] @punctuation.bracket
["," "." "=" ":"] @punctuation.delimiter