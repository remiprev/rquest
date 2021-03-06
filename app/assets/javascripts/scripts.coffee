class Rquest

  GENDERS =
    m: 'his'
    f: 'her'

  KEYS =
    escape: 27
    up: 38
    down: 40
    enter: 13

  constructor: ->
    @html = $('html')

    this.initGender()
    this.initUsername()
    this.initPlaylists()
    this.initSongs()

  # Gender management
  initGender: ->
    @genderSpan = $('#gender')
    @currentGender = GENDERS.m

  updateGender: (genderKey) ->
    gender = GENDERS[genderKey]

    return if gender is @currentGender
    @currentGender = gender

    @genderSpan.html(gender)

  # Username management
  initUsername: ->
    @currentUsername = ''
    @usernameInput = $('#username')
    @userInput = $('input[name="user"]')
    @userSpan = $('#user')
    @avatarSpan = @userSpan.children('.icon')

    @usernameInput.on 'blur', (e) =>
      username = @usernameInput.val().toLowerCase()

      return if username is @currentUsername
      @currentUsername = username
      @playlistsSelect.attr('disabled', true)

      if username is ''
        @userSpan.removeClass('has-icon')
        @avatarSpan.html('')
        return

      @html.addClass('loading')

      $.ajax
        url: "/#{username}/playlists"
        success: (data) =>
          @html.removeClass('loading')
          @userSpan.removeClass('has-icon')
          @avatarSpan.html('')
          return unless data

          data = JSON.parse(data)
          @userInput.val(JSON.stringify(data.user))

          this.updateUser(data.user)
          this.updateGender(data.user.gender)
          this.updatePlaylists(data.playlists)

    @usernameInput.on 'keypress', (e) =>
      return unless e.keyCode is KEYS.enter
      @usernameInput.trigger('blur')

  updateUser: (user) ->
    @avatarSpan.html "<img src='#{user.icon}' alt='#{user.firstName}'>"
    @userSpan.addClass('has-icon')

  # Playlists management
  initPlaylists: ->
    @playlistsSelect = $('select[name="playlists"]')

  updatePlaylists: (playlists) ->
    playlistsHtml = ''

    for playlist in playlists
      playlistsHtml += "<option value='#{JSON.stringify(playlist)}'>#{playlist.name}</option>"

    @playlistsSelect.removeAttr('disabled')
    @playlistsSelect.html(playlistsHtml)

  # Songs management
  initSongs: ->
    @currentSong = ''
    searchTimer = null
    @songRequest = null
    @songInput = $('input[name="song"]')
    @songNameInput = $('#song-name')
    @songSpan = $('#song')
    @songList = @songSpan.children('ul')
    @songIconSpan = @songSpan.children('.icon')

    @songNameInput.on 'keyup', (e) =>
      clearTimeout(searchTimer)
      searchTimer = setTimeout =>
        song = @songNameInput.val()

        return if song is @currentSong
        @currentSong = song

        return if song is ''
        @html.addClass('loading')
        @songRequest?.abort()

        @songRequest = $.ajax
          url: "/search/#{song.replace(' ', '+')}"
          success: (data) =>
            @html.removeClass('loading')
            return unless data

            data = JSON.parse(data)
            this.updateSongs(data.results) if data.results.length > 0
      , 250

    @songNameInput.on 'keydown', (e) =>
      return unless e.keyCode is KEYS.down
      e.preventDefault()

      if ($li = @songList.find('li:first-child a')).length
        $li.focus()

    @songList.on 'click', 'a', (e) =>
      $target = $(e.currentTarget)

      song = $target.attr('data-name')
      songData = $target.attr('data-song')
      songIcon = $target.attr('data-icon')

      @songNameInput.val(song)
      @songInput.val(songData)
      @songIconSpan.html("<img src='#{songIcon}' alt='#{song}'>")
      @songSpan.addClass('has-icon')

      this.updateSongs()

    @songList.on 'keydown', 'a', (e) =>
      return if [KEYS.up, KEYS.down].indexOf(e.keyCode) is -1
      e.preventDefault()

      $target = $(e.currentTarget)
      $parent = $target.parent('li')

      switch e.keyCode
        when KEYS.up
          if ($prevLi = $parent.prev('li')).length
            $prevLi.children('a').focus()
          else
            @songNameInput.focus()
        when KEYS.down
          $parent.next('li').children('a').focus()

    $(document).on 'keydown', (e) =>
      return unless e.keyCode is KEYS.escape
      this.updateSongs()

  updateSongs: (songs=[]) ->
    return @songList.html('') unless songs.length
    songsHtml = ''

    for song in songs
      songsHtml += """
        <li>
          <a data-name="#{song.name}" data-song='#{JSON.stringify(song)}' data-icon="#{song.icon}" href="javascript:">
            <div class="img">
              <img src="#{song.icon}">
            </div>
            <div class="song">
              <span class="name">#{song.name}</span>
              <span class="artist">#{song.albumArtist}</span>
            </div>
          </a>
        </li>"""

    @songList.html(songsHtml)


# Initialization
new Rquest
