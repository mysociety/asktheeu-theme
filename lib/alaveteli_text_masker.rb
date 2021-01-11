require 'alaveteli_text_masker'

module AlaveteliTextMasker
  private

  def uncompress_pdf(text)
    AlaveteliExternalCommand.run("pdftk", "-", "output", "-", "uncompress", :stdin_string => text, :timeout => 300)
  end

  def compress_pdf(text)
    if AlaveteliConfiguration::use_ghostscript_compression
      command = ["gs",
                 "-sDEVICE=pdfwrite",
                 "-dCompatibilityLevel=1.4",
                 "-dPDFSETTINGS=/screen",
                 "-dNOPAUSE",
                 "-dQUIET",
                 "-dBATCH",
                 "-sOutputFile=-",
                 "-"]
    else
      command = ["pdftk", "-", "output", "-", "compress"]
    end
    AlaveteliExternalCommand.run(*(command + [ :stdin_string => text, :timeout => 300 ]))
  end
end
