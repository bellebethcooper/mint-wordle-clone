component Link {
  property children : Array(Html) = []
  property href : String

  style link {
    // font-size: calc(10px + 2vmin);
    text-decoration: none;
    color: #f7b100;

    &:hover {
      text-decoration: underline;
    }
  }

  fun render : Html {
    <a::link
      href="#{href}"
      target="_blank">

      <{ children }>

    </a>
  }
}
