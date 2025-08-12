/*
 * habitat_goal_type
 * -----------------
 * The goal for surface and/or quality, in the context of habitat types:
 * =       level
 * >       increase
 * = (>)   increase while maintaining properly developed locations
 * <       decrease is allowed, in favor of another specific habitat type
 * = (<)   decrease is allowed in favor of another habitat type
 * > (<)   surface should be increased, but is allowed to decrease in favor of another habitat type
 *
 * Goal for habitat and/or populace, in the context of species, breeding birds, non-breeding birds:
 * =       level
 * >       increase/improvement
 * <       decrease is allowed
 * = (<)   decrease in favor of another species is allowed
 */
CREATE TYPE habitat_goal_type AS ENUM
	('specified', 'none', 'level', 'increase', 'level_increase', 'decrease', 'level_decrease', 'increase_may_decrease');

/*
 * species_type
 * ------------
 * The type of a (animal) species which are present in a habitat.
 */
CREATE TYPE species_type AS ENUM
	('habitat_species', 'breeding_bird_species', 'non_breeding_bird_species');

/*
 * critical_deposition_classification
 * ----------------------------------
 * Enum type for critical load (KDW, Kritische Depositie Waarde) classifications.
 */
CREATE TYPE critical_deposition_classification AS ENUM
	('high_sensitivity', 'normal_sensitivity', 'low_sensitivity');
