#===============================================================================
# Level Scaling
# By supersand24
#===============================================================================

EventHandlers.add(:on_wild_pokemon_created, :level_scaling,
  proc { |pokemon|
    old_level = pokemon.level
    LevelScaling.wildPokemon(pokemon)
	  echoln "#{pokemon.species} level #{old_level} -> #{pokemon.level}"

    LevelScaling.resetToDefaultSettings()
  }
)

EventHandlers.add(:on_trainer_load, :level_scaling,
  proc { |trainer|
    if trainer != 0
      average_level = 0
      trainer.party.each { |pokemon| average_level += pokemon.level }
      average_level /= trainer.party.length

      for pokemon in trainer.party
        old_level = pokemon.level
        LevelScaling.trainerPokemon(pokemon)
        echoln "#{pokemon.species} level #{old_level} -> #{pokemon.level}"
      end
    end

    LevelScaling.resetToDefaultSettings()
  }
)

EventHandlers.add(:on_end_battle, :update_partner_levels,
  proc { |_decision, _canLose|
    if $PokemonGlobal.partner != nil
      average_level = 0
      $PokemonGlobal.partner[3].each { |pokemon| average_level += pokemon.level }
      average_level /= $PokemonGlobal.partner[3].length

      for pokemon in $PokemonGlobal.partner[3] do
        pokemon.level = pokemon.level - average_level
      end
    end
  }
)

class LevelScaling
  
  def self.trainerPokemon(pokemon)
    # Evolution part
    LevelScaling.setNewStage(pokemon, true) if @@settings[:automatic_evolutions]

    pokemon.calc_stats
    pokemon.reset_moves if @@settings[:update_moves]
  end

  def self.wildPokemon(pokemon)
    new_level = pbBalancedLevel($player.party) - ( @@settings[:base_minus] )
    echoln "Max Level: #{pbGet(26)} | Party Level: #{new_level}"
    pokemon.level += new_level.clamp(1, pbGet(26))
	  pokemon.obtain_level = pokemon.level

    # Evolution part
    LevelScaling.setNewStage(pokemon, false) if @@settings[:automatic_evolutions]

    pokemon.calc_stats
    pokemon.reset_moves if @@settings[:update_moves]
  end

  def self.setNewStage(pokemon, trainerBattle = false)

    # revert pokemon to it's first stage
    # pokemon.species = GameData::Species.get(pokemon.species).get_baby_species

    begin
      repeat = false
      #echoln "#{pokemon.species} evolutions"
      evolutions = GameData::Species.get(pokemon.species).get_evolutions
      for evolution in evolutions
        # Evolutions you would see in Trainer and Wild Battles.
        case evolution[1]
        when :Level
          evolvePokemon(pokemon, evolution) if pokemon.level >= evolution[2]
        when :LevelMale
          if pokemon.level >= evolution[2] && pokemon.gender == 0
            echoln "#{pokemon.species} evolved into #{evolution[0]} with method: #{evolution[1]}"
            pokemon.species = evolution[0]
            repeat = true
          end
        when :LevelFemale
          if pokemon.level >= evolution[2] && pokemon.gender == 1
            echoln "#{pokemon.species} evolved into #{evolution[0]} with method: #{evolution[1]}"
            pokemon.species = evolution[0]
            repeat = true
          end
        else
          # Evolutions you would see in Trainer Battles.
          if trainerBattle
            case evolution[1]
            when :Item
              if pokemon.level >= 20
                echoln "#{pokemon.species} evolved into #{evolution[0]} with method: #{evolution[1]}"
                pokemon.species = evolution[0]
                repeat = true
              end
            else
              echoln "Unhandled evo method: #{evolution[1]}"
            end

          # Evolutions you would see in Wild Battles.
          else
            case evolution[1]
            when :Level
              echoln "Placeholder"
            else
              echoln "Unhandled evo method: #{evolution[1]}"
            end

          end

        end

      end

    end while repeat == true

  end # setNewStage

  def self.evolvePokemon(pokemon, evolution)
    echoln "#{pokemon.species} evolved into #{evolution[0]} with method: #{evolution[1]}"
    pokemon.species = evolution[0]
    repeat = true
  end

  def self.setTemporarySetting(setting, value)
    # Parameters validation
    case setting
    when "firstEvolutionLevel", "secondEvolutionLevel"
      if !value.is_a?(Integer)
        raise _INTL("\"{1}\" requires an integer value, but {2} was provided.",setting,value)
      end
    when "updateMoves", "automaticEvolutions"
      if !(value.is_a?(FalseClass) || value.is_a?(TrueClass))
        raise _INTL("\"{1}\" requires a boolean value, but {2} was provided.",setting,value)
      end
    else
      raise _INTL("\"{1}\" is not a defined setting name.",setting)
    end

    @@settings[:temporary] = true
    case setting
    when "updateMoves"
      @@settings[:update_moves] = value
    when "automaticEvolutions"
      @@settings[:automatic_evolutions] = value
    when "firstEvolutionLevel"
      @@settings[:first_evolution_level] = value
    when "secondEvolutionLevel"
      @@settings[:second_evolution_level] = value
    end
  end

  def self.resetToDefaultSettings()
    if @@settings[:temporary]
      setSettings()
    end
  end

  def self.setSettings()
    @@settings = {
      temporary: false,
      first_evolution_level: 20,
      second_evolution_level: 40,
      base_minus: 7,
      update_moves: true,
      automatic_evolutions: true
    }
  end

  setSettings()

end # LevelScaling Class end
